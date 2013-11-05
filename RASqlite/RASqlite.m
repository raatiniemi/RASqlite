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
@private NSString *_path;
}

/**
 Stores the path for the database file.
 */
@property (nonatomic, readwrite, strong) NSString *path;

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

 @return Row with the column names and their values.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The dictionary will contain the Foundation representations of the SQLite data types,
 e.g. `SQLITE_INTEGER` will be `NSNumber`, `SQLITE_NULL` will be `NSNull`, etc.
 */
- (RASqliteRow *)fetchColumns:(sqlite3_stmt **)statement withError:(RASqliteError **)error;

@end

@implementation RASqlite

@synthesize path = _path;

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

- (instancetype)initWithName:(NSString *)name
{
	if ( self = [super init] ) {
		// Setup the correct path for the iOS document folder.
		NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		[self setPath:[NSString stringWithFormat:@"%@/%@", [directories objectAtIndex:0], name]];

		// Create the thread for running queries, using the name for the database file.
		NSString *thread = [NSString stringWithFormat:kRASqliteThreadFormat, name];
		_queue = dispatch_queue_create([thread UTF8String], NULL);
	}
	return self;
}

- (instancetype)initWithPath:(NSString *)path
{
	// Incomplete implementation warning.
	[NSException raise:@"Incomplete implementation"
				format:@"Use of the `initWithPath:` method have not fully been implemented."];

	// TODO: Create the query thread for `initWithPath:`.

	// Return nil, takes care of the return warning.
	return nil;
}

#pragma mark - Database

- (void)setDatabase:(sqlite3 *)database
{
	// Protection from rewriting the database pointer mid execution. The pointer
	// have to be resetted before setting a new instance.
	if ( _database == nil || database == nil ) {
		_database = database;
	}
}

- (sqlite3 *)database
{
	return _database;
}

- (RASqliteError *)openWithFlags:(int)flags
{
	RASqliteError __block *error;

	void (^block)(void) = ^(void) {
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
	};

	// TODO: Documentation.
	// Reminder: The strcmp function returns zero if the strings are equal.
	if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
		block();
	} else {
		dispatch_sync(_queue, block);
	}

	return error;
}

- (RASqliteError *)open
{
	return [self openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE];
}

- (RASqliteError *)close
{
	RASqliteError __block *error;

	void (^block)(void) = ^(void) {
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
	};

	// TODO: Documentation.
	// Reminder: The strcmp function returns zero if the strings are equal.
	if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
		block();
	} else {
		dispatch_sync(_queue, block);
	}

	return error;
}

#pragma mark - Table

- (BOOL)check
{
	RASqliteError __block *error = [self error];

	void (^block)(void) = ^(void) {
		NSDictionary *tables = [self structure];
		if ( tables ) {
			for ( NSString *table in tables ) {
				if ( ![self checkTable:table withColumns:[tables objectForKey:table]] ) {
					error = [self error];
					break;
				}
			}
		} else {
			// TODO: Correct error code.
			error = [RASqliteError code:0
								message:@"Unable to check database structure, none has been supplied."];
		}
	};

	if ( !error ) {
		// TODO: Documentation.
		// Reminder: The strcmp function returns zero if the strings are equal.
		if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
			block();
		} else {
			dispatch_sync(_queue, block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
}

- (BOOL)checkTable:(NSString *)table withColumns:(NSDictionary *)columns
{
	RASqliteError __block *error = [self error];

	if ( !table ) {
		// TODO: Correct error code.
		error = [RASqliteError code:0
							message:@"Unable to check table without valid name."];
	}

	if ( !columns ) {
		// TODO: Correct error code.
		error = [RASqliteError code:0
							message:@"Unable to check table without defined columns."];
	}

	void (^block)(void) = ^(void) {
		NSArray *tColumns = [self fetch:[NSString stringWithFormat:@"PRAGMA table_info(%@)", table]];

		if ( [tColumns count] == [columns count] ) {
			unsigned int index = 0;
			for ( NSString *column in columns ) {
				RASqliteRow *tColumn = [tColumns objectAtIndex:index];
				if ( ![[tColumn getColumn:@"name"] isEqualToString:column] ) {
					// TODO: Correct error code.
					NSString *message = @"Column name `%@` do not match index `%i` for the given structure.";
					error = [RASqliteError code:0 message:message, table, index];
					break;
				}

				NSString *type = [columns objectForKey:column];
				if ( ![[tColumn getColumn:@"type"] isEqualToString:type] ) {
					// TODO: Correct error code.
					NSString *message = @"Column type `%@` to not match index `%i` for given structure.";
					error = [RASqliteError code:0 message:message, table, index];
					break;
				}
				index++;
			}
		} else {
			// TODO: Correct error code.
			NSString *message = @"Number of specified columns for table `%@` do not matched the defined table count.";
			error = [RASqliteError code:0 message:message, table];
		}
	};

	if ( !error ) {
		// TODO: Documentation.
		// Reminder: The strcmp function returns zero if the strings are equal.
		if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
			block();
		} else {
			dispatch_sync(_queue, block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
}

- (BOOL)create
{
	RASqliteError __block *error = [self error];

	void (^block)(void) = ^(void) {
		NSDictionary *tables = [self structure];
		if ( tables ) {
			for ( NSString *table in tables ) {
				if ( ![self createTable:table withColumns:[tables objectForKey:table]] ) {
					error = [self error];
					break;
				}
			}
		} else {
			// TODO: Correct error code.
			error = [RASqliteError code:0
								message:@"Unable to check database structure, none has been supplied."];
		}
	};

	if ( !error ) {
		// TODO: Documentation.
		// Reminder: The strcmp function returns zero if the strings are equal.
		if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
			block();
		} else {
			dispatch_sync(_queue, block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
}

- (BOOL)createTable:(NSString *)table withColumns:(NSDictionary *)columns
{
	RASqliteError __block *error = [self error];

	if ( !table ) {
		// TODO: Correct error code.
		error = [RASqliteError code:0
							message:@"Unable to check table without valid name."];
	}

	if ( !columns ) {
		// TODO: Correct error code.
		error = [RASqliteError code:0
							message:@"Unable to check table without defined columns."];
	}

	void (^block)(void) = ^(void) {
		NSMutableString *sql = [[NSMutableString alloc] init];
		[sql appendFormat:@"CREATE TABLE IF NOT EXISTS %@(", table];

		NSUInteger index = 0;
		for ( NSString *name in columns ) {
			if ( index > 0 ) {
				[sql appendString:@","];
			}
			[sql appendFormat:@"%@ ", name];

			NSArray *types = @[kRASqliteNull, kRASqliteReal, kRASqliteText, kRASqliteBlob, kRASqliteInteger];
			NSString *type = [columns objectForKey:name];
			if ( [types indexOfObject:type] != NSNotFound ) {
				[sql appendString:type];

				if ( [kRASqliteInteger isEqualToString:type] ) {
					if ( [name isEqualToString:@"id"] ) {
						[sql appendString:@" PRIMARY KEY"];
					} else {
						[sql appendString:@" DEFAULT 0"];
					}
				}
			} else {
				error = [RASqliteError code:0
									message:@"Unrecognized SQLite data type: %@", type];
			}

			index++;
		}
		[sql appendString:@");"];

		if ( !error ) {
			[self execute:sql];
		}
	};

	if ( !error ) {
		// TODO: Documentation.
		// Reminder: The strcmp function returns zero if the strings are equal.
		if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
			block();
		} else {
			dispatch_sync(_queue, block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
}

#pragma mark - Query

- (RASqliteError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement
{
	RASqliteError *error;

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

- (RASqliteRow *)fetchColumns:(sqlite3_stmt **)statement withError:(RASqliteError **)error
{
	unsigned int count = sqlite3_column_count(*statement);
	RASqliteRow *row = [RASqliteRow columns:count];

	const char *name;
	NSString *column;

	unsigned int index;
	int type;
	// Loop through the columns, or until an error is encountered.
	for ( index = 0; !*error && index < count; index++ ) {
		name = sqlite3_column_name(*statement, index);
		column = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

		// TODO: Implement support for the rest of the `sqlite3_column_*` functions.
		type = sqlite3_column_type(*statement, index);
		switch ( type ) {
			case SQLITE_INTEGER: {
				// TODO: Handle retrieval of sqlite3_int64.
				int value = sqlite3_column_int(*statement, index);
				[row setColumn:column withValue:[NSNumber numberWithInt:value]];
				break;
			}
			case SQLITE_FLOAT: {
				double value = sqlite3_column_double(*statement, index);
				[row setColumn:column withValue:[NSNumber numberWithDouble:value]];
				break;
			}
			case SQLITE_BLOB: {
				// TODO: Implement support for SQLITE_BLOB.
				*error = [RASqliteError code:RASqliteErrorImplementation
									 message:@"Incomplete implementation of `fetchColumns:` for `SQLITE_BLOB`."];
				break;
			}
			case SQLITE_NULL: {
				[row setColumn:column withValue:[NSNull null]];
				break;
			}
			case SQLITE_TEXT:
			default: {
				const char *value = (const char *)sqlite3_column_text(*statement, index);
				[row setColumn:column withValue:[NSString stringWithCString:value encoding:NSUTF8StringEncoding]];
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

	void (^block)(void) = ^(void) {
		// If database is not open, attempt to open it.
		if ( ![self database] ) {
			error = [self open];
		}

		// If an error already have occurred, we should not attempt to execute query.
		if ( !error ) {
			sqlite3_stmt *statement;
			int code = sqlite3_prepare([self database], [sql UTF8String], -1, &statement, NULL);

			if ( code == SQLITE_OK ) {
				if ( params ) {
					error = [self bindColumns:params toStatement:&statement];
				}

				if ( !error ) {
					RASqliteRow *row;
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
				}

				// If the error variable have been populated, something
				// has gone wrong and we need to reset the results variable.
				if ( error ) {
					results = nil;
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
		}
	};

	if ( !error ) {
		// TODO: Documentation.
		// Reminder: The strcmp function returns zero if the strings are equal.
		if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
			block();
		} else {
			dispatch_sync(_queue, block);
		}
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

- (RASqliteRow *)fetchRow:(NSString *)sql withParams:(NSArray *)params
{
	RASqliteError __block *error = [self error];
	RASqliteRow __block *row;

	void (^block)(void) = ^(void) {
		// If database is not open, attempt to open it.
		if ( ![self database] ) {
			error = [self open];
		}

		// If an error already have occurred, we should not attempt to execute query.
		if ( !error ) {
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
		}
	};

	if ( !error ) {
		// TODO: Documentation.
		// Reminder: The strcmp function returns zero if the strings are equal.
		if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
			block();
		} else {
			dispatch_sync(_queue, block);
		}
	}

	return row;
}

- (RASqliteRow *)fetchRow:(NSString *)sql withParam:(id)param
{
	return [self fetchRow:sql withParams:@[param]];
}

- (RASqliteRow *)fetchRow:(NSString *)sql
{
	return [self fetchRow:sql withParams:nil];
}

#pragma mark -- Update

- (BOOL)execute:(NSString *)sql withParams:(NSArray *)params
{
	RASqliteError __block *error = [self error];

	void (^block)(void) = ^(void) {
		// If database is not open, attempt to open it.
		if ( ![self database] ) {
			error = [self open];
		}

		// If an error already have occurred, we should not attempt to execute query.
		if ( !error ) {
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
		}
	};

	if ( !error ) {
		// TODO: Documentation.
		// Reminder: The strcmp function returns zero if the strings are equal.
		if ( !strcmp(RASqliteQueueLabel, dispatch_queue_get_label(_queue)) ) {
			block();
		} else {
			dispatch_sync(_queue, block);
		}
	}

	return error == nil;
}

- (BOOL)execute:(NSString *)sql withParam:(id)param
{
	return [self execute:sql withParams:@[param]];
}

- (BOOL)execute:(NSString *)sql
{
	return [self execute:sql withParams:nil];
}

#pragma mark -- Queue

- (void)queueWithBlock:(void (^)(RASqlite *db))block
{
	dispatch_sync(_queue, ^{
		block(self);
	});
}

- (void)queueTransactionWithBlock:(void (^)(RASqlite *db, BOOL **commit))block
{
	// TODO: Start transaction.
	dispatch_sync(_queue, ^{
		BOOL *commit;

		block(self, &commit);

		if ( commit ) {
//			[self commit];
		} else {
//			[self rollBack];
		}
	});
}

@end