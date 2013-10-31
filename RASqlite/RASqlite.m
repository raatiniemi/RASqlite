//
//  RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RASqlite.h"

static sqlite3 *_database;

@interface RASqlite () {
@private NSString *_name;

@private RASqliteError *_error;
}

/**
 Stores the name of the database file.
 */
@property (nonatomic, readwrite, strong) NSString *name;

#pragma mark - Database

/**
 Set the database instance.

 @param database Database instance.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)setDatabase:(sqlite3 *)database;

#pragma mark - Query

/**
 Bind the parameters to the statement.

 @param columns Parameters to bind to the statement.
 @param statement Statement on which the parameters will be binded.
 
 @return `nil` if binding is successful, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (RASqliteError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement;

/**
 Fetch the retrieved columns from the SQL query.

 @param statement Statement from which to retrieve the columns.
 @param error If an error occurred, variable will be populated (pass-by-reference).

 @return Dictionary with the column names and their values.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The dictionary will contain the Foundation representations of the SQLite data types,
 e.g. `SQLITE_INTEGER` will be `NSNumber`, `SQLITE_NULL` will be `NSNull`, etc.
 */
- (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement withError:(RASqliteError **)error;

@end

@implementation RASqlite

@synthesize name = _name;

@synthesize error = _error;

#pragma mark - Initialization

- (id)init
{
	// Use of this method is not allowed, `initWithName:` should be used.
	[NSException raise:@"Incorrect initialization"
				format:@"Use of the `init` method is not allowed, use `initWithName:` instead."];

	// Return nil, takes care of the return warning.
	return nil;
}

- (id)initWithName:(NSString *)name
{
	if ( self = [super init] ) {
		[self setName:name];

		// Assemble the thread name for the database queue.
		// TODO: Migrate thread format to constant.
		NSString *thread = [NSString stringWithFormat:@"me.raatiniemi.rasqlite.%@", [self name]];
		_queue = dispatch_queue_create([thread UTF8String], NULL);
	}
	return self;
}

#pragma mark - Database

- (void)setDatabase:(sqlite3 *)database
{
	_database = database;
}

- (sqlite3 *)database
{
	return _database;
}

- (NSString *)path
{
	// TODO: Implement support for custom paths for OS X, `initWithPath:`.
	// Current implementation is aimed at iOS development. On OS X this puts the
	// database file within the User documents folder.
	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [NSString stringWithFormat:@"%@/%@", [directories objectAtIndex:0], [self name]];
}

- (RASqliteError *)openWithFlags:(int)flags
{
	RASqliteError __block *error;

	// TODO: Migrate thread name to constant.
	// TODO: Make thread unique for database.
	dispatch_sync(dispatch_queue_create("me.raatiniemi.rasqlite.open", NULL), ^{
		sqlite3 *database = [self database];
		if ( !database ) {
			int code = sqlite3_open_v2([[self path] UTF8String], &database, flags, NULL);
			if ( code == SQLITE_OK ) {
				// TODO: Debug message, database have successfully been opened.
				NSLog(@"Database have successfully been opened.");

				[self setDatabase:database];
			} else {
				error = [RASqliteError code:RASqliteErrorOpen
									message:@"Unable to open database, received code `%i`.", code];
			}
		} else {
			// TODO: Debug message, database is already open.
			NSLog(@"Database is already open.");
		}
	});

	return error;
}

- (RASqliteError *)open
{
	return [self openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE];
}

- (RASqliteError *)close
{
	RASqliteError __block *error;

	// TODO: Migrate thread name to constant.
	// TODO: Make thread unique for database.
	dispatch_sync(dispatch_queue_create("me.raatiniemi.rasqlite.close", NULL), ^{
		sqlite3 *database = [self database];
		if ( database ) {
			BOOL retry;
			int code;

			do {
				// Reset the retry control and attempt to close the database.
				retry = NO;
				code = sqlite3_close(database);

				// TODO: Check if database is locked or busy and attempt a retry.
				// TODO: Handle retry infinite loop.
				if ( code != SQLITE_OK ) {
					error = [RASqliteError code:RASqliteErrorClose
										message:@"Unable to close database, received code `%i`.", code];
				} else {
					// TODO: Debug message, database have successfully been closed.
					NSLog(@"Database have successfully been closed.");

					[self setDatabase:nil];
				}
			} while (retry);
		} else {
			// TODO: Debug message, database is already closed.
			NSLog(@"Database is already closed.");
		}
	});

	return error;
}

#pragma mark - Query

- (RASqliteError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement
{
	RASqliteError __block *error;

	int code = SQLITE_OK;
	unsigned int index = 1;
	for ( id column in columns ) {
		if ( [column isKindOfClass:[NSString class]] ) {
			// TODO: Check if string is UTF-8 or UTF-16.
			code = sqlite3_bind_text(*statement, index, [column UTF8String], -1, SQLITE_TRANSIENT);
		} else if ( [column isKindOfClass:[NSNumber class]] ) {
			const char *type = [column objCType];
			if ( strcmp(type, @encode(double)) == 0 || strcmp(type, @encode(float)) == 0 ) {
				// Both double and float should be binded as double.
				code = sqlite3_bind_double(*statement, index, [column doubleValue]);
			} else if ( strcmp(type, @encode(long)) == 0 || strcmp(type, @encode(long long)) == 0 ) {
				code = sqlite3_bind_int64(*statement, index, [column longLongValue]);
			} else {
				// Every data type that is not specified should be binded as int.
				code = sqlite3_bind_int(*statement, index, [column intValue]);
			}
		} else if ( [column isKindOfClass:[NSNull class]] ) {
			code = sqlite3_bind_null(*statement, index);
		} else {
			// TODO: Implement support for more data types.
			error = [RASqliteError code:RASqliteErrorImplementation
								message:@"Support for binding type `%@` is not available.", [column class]];
		}

		if ( !error && code != SQLITE_OK ) {
			error = [RASqliteError code:RASqliteErrorBind
								message:@"Unable to bind type `%@`.", [column class]];
		}

		if ( error ) {
			break;
		}
		index++;
	}

	return error;
}

- (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement withError:(RASqliteError **)error
{
	unsigned int count = sqlite3_column_count(*statement);
	NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:count];

	const char *name;
	NSString *column;

	unsigned int index;
	int type;
	for ( index = 0; !*error && index < count; index++ ) {
		name = sqlite3_column_name(*statement, index);
		column = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

		// TODO: Implement support for the rest of the `sqlite3_column_*` functions.
		type = sqlite3_column_type(*statement, index);
		switch ( type ) {
			case SQLITE_INTEGER: {
				// TODO: Handle retrieval of sqlite3_int64.
				int value = sqlite3_column_int(*statement, index);
				[row setObject:[NSNumber numberWithInt:value] forKey:column];
				break;
			}
			case SQLITE_FLOAT: {
				double value = sqlite3_column_double(*statement, index);
				[row setObject:[NSNumber numberWithDouble:value] forKey:column];
				break;
			}
			case SQLITE_BLOB: {
				// TODO: Implement support for SQLITE_BLOB.
				*error = [RASqliteError code:RASqliteErrorImplementation
									 message:@"Incomplete implementation of `fetchColumns:` for `SQLITE_BLOB`."];
				break;
			}
			case SQLITE_NULL: {
				[row setObject:[NSNull null] forKey:column];
				break;
			}
			case SQLITE_TEXT:
			default: {
				const char *value = (const char *)sqlite3_column_text(*statement, index);
				[row setObject:[NSString stringWithCString:value encoding:NSUTF8StringEncoding] forKey:column];
				break;
			}
		}
	}

	// If the error variable have been populated, something has gone wrong and
	// we need to reset the row variable.
	if ( *error ) {
		row = nil;
	}

	return row;
}

#pragma mark -- Fetch

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params
{
	RASqliteError __block *error = [self error];
	NSMutableArray __block *results;

	// If an error already have occurred, we should not attempt to execute query.
	if ( !error ) {
		dispatch_sync(_queue, ^{
			// If database is not open, attempt to open it.
			if ( ![self database] ) {
				error = [self open];
			}

			sqlite3_stmt *statement;
			int code = sqlite3_prepare([self database], [sql UTF8String], -1, &statement, NULL);

			if ( code == SQLITE_OK ) {
				if ( params ) {
					error = [self bindColumns:params toStatement:&statement];
				}

				if ( !error ) {
					NSDictionary *row;
					results = [[NSMutableArray alloc] init];

					// Looping through the results, until an error occurres or
					// the query is done.
					do {
						code = sqlite3_step(statement);

						if ( code == SQLITE_ROW ) {
							row = [self fetchColumns:&statement withError:&error];
							[results addObject:row];
						} else if ( code == SQLITE_DONE ) {
							// Results have been fetch, leave the loop.
							break;
						} else {
							// Something has gone wrong, leave the loop.
							error = [RASqliteError code:RASqliteErrorQuery
												message:@"Unable to fetch row, received code `%i`.", code];
							break;
						}
					} while ( !error );

					// If the error variable have been populated, something
					// has gone wrong and we need to reset the results variable.
					if ( error ) {
						results = nil;
					}
				}
			} else {
				error = [RASqliteError code:RASqliteErrorQuery
									message:@"Failed to prepare statement `%@`, received code `%i`.", sql, code];
			}
			sqlite3_finalize(statement);

			// If an error occurred performing the query set the error. However,
			// do not override the existing error, if it exists.
			if ( ![self error] && error ) {
				[self setError:error];
			}
		});
	} else {
		// TODO: Debug message, existing error has not been cleared.
		NSLog(@"Existing error has not been cleared, aborting...");
	}

	return results;
}

- (NSArray *)fetch:(NSString *)sql withParam:(id)param
{
	return [self fetch:sql withParams:@[param]];
}

- (NSArray *)fetch:(NSString *)sql
{
	return [self fetch:sql withParams:nil];
}

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params
{
	RASqliteError __block *error = [self error];
	NSDictionary __block *row;

	// If an error already have occurred, we should not attempt to execute query.
	if ( !error ) {
		dispatch_sync(_queue, ^{
			// If database is not open, attempt to open it.
			if ( ![self database] ) {
				error = [self open];
			}

			sqlite3_stmt *statement;
			int code = sqlite3_prepare([self database], [sql UTF8String], -1, &statement, NULL);

			if ( code == SQLITE_OK ) {
				if ( params ) {
					error = [self bindColumns:params toStatement:&statement];
				}

				if ( !error ) {
					code = sqlite3_step(statement);
					if ( code == SQLITE_ROW ) {
						row = [self fetchColumns:&statement withError:&error];

						// If the error variable have been populated, something
						// has gone wrong and we need to reset the row variable.
						if ( error || [row count] == 0 ) {
							row = nil;
						}
					} else if ( code == SQLITE_DONE ) {
						// TODO: Debug message, no rows were found.
						NSLog(@"No rows were found with query: `%@`", sql);
					} else {
						error = [RASqliteError code:RASqliteErrorQuery
											message:@"Failed to retrieve result, received code: `%i`", code];
					}
				}
			} else {
				error = [RASqliteError code:RASqliteErrorQuery
									message:@"Failed to prepare statement `%@`, received code `%i`.", sql, code];
			}
			sqlite3_finalize(statement);

			// If an error occurred performing the query set the error. However,
			// do not override the existing error, if it exists.
			if ( ![self error] && error ) {
				[self setError:error];
			}
		});
	} else {
		// TODO: Debug message, existing error has not been cleared.
		NSLog(@"Existing error has not been cleared, aborting...");
	}

	return row;
}

- (NSDictionary *)fetchRow:(NSString *)sql withParam:(id)param
{
	return [self fetchRow:sql withParams:@[param]];
}

- (NSDictionary *)fetchRow:(NSString *)sql
{
	return [self fetchRow:sql withParams:nil];
}

#pragma mark -- Update

- (RASqliteError *)execute:(NSString *)sql withParams:(NSArray *)params
{
	RASqliteError __block *error = [self error];

	// If an error already have occurred, we should not attempt to execute query.
	if ( !error ) {
		dispatch_sync(_queue, ^{
			// If database is not open, attempt to open it.
			if ( ![self database] ) {
				error = [self open];
			}

			sqlite3_stmt *statement;
			int code = sqlite3_prepare([self database], [sql UTF8String], -1, &statement, NULL);

			if ( code == SQLITE_OK ) {
				if ( params ) {
					error = [self bindColumns:params toStatement:&statement];
				}

				if ( !error ) {
					code = sqlite3_step(statement);
					if ( code != SQLITE_DONE ) {
						error = [RASqliteError code:RASqliteErrorQuery
											message:@"Failed to retrieve result, received code: `%i`", code];
					}
				}
			} else {
				error = [RASqliteError code:RASqliteErrorQuery
									message:@"Failed to prepare statement `%@`, recived code `%i`.", sql, code];
			}
			sqlite3_finalize(statement);

			// If an error occurred performing the query set the error. However,
			// do not override the existing error, if it exists.
			if ( ![self error] && error ) {
				[self setError:error];
			}
		});
	} else {
		// TODO: Debug message, existing error has not been cleared.
		NSLog(@"Existing error has not been cleared, aborting...");
	}

	return error;
}

- (RASqliteError *)execute:(NSString *)sql withParam:(id)param
{
	return [self execute:sql withParams:@[param]];
}

- (RASqliteError *)execute:(NSString *)sql
{
	return [self execute:sql withParams:nil];
}

@end