//
//  RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import "RASqlite.h"

@interface RASqlite () {
@private
	NSString *_name;
	NSString *_path;
}

@property (nonatomic, readwrite, strong) NSString *name;

@property (nonatomic, readonly, strong) NSString *path;

@end

@implementation RASqlite

@synthesize name = _name;

@synthesize path = _path;

@synthesize database = _database;

@synthesize error = _error;

- (id)init
{
	// Use of this method is not allowed, `initWithName:` should be used.
	[NSException raise:@"Incorrect initialization"
				format:@"Use of the `init` method is not allowed, use `initWithName:` instead."];

	return nil;
}

- (id)initWithName:(NSString *)name
{
	if ( self = [super init] ) {
		[self setName:name];
	}
	return self;
}

- (NSString *)path
{
	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [directories objectAtIndex:0];

	return [NSString stringWithFormat:@"%@/%@", path, [self name]];
}

- (void)open
{
	sqlite3 *database = [self database];
	if ( database == nil ) {
		int code = sqlite3_open_v2([[self path] UTF8String], &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE, NULL);
		if ( code == SQLITE_OK ) {
			NSString *filename = [NSString stringWithCString:sqlite3_db_filename(database, NULL) encoding:NSUTF8StringEncoding];
			RASqliteLog(@"Database `%@` have been successfully opened.", [filename lastPathComponent]);
			[self setDatabase:database];
		} else {
			NSString *description = @"Unable to open database: `%s`";
			[self setError:[self errorWithDescription:[NSString stringWithFormat:description, sqlite3_errmsg([self database])] code:code]];
		}
	} else {
		NSString *filename = [NSString stringWithCString:sqlite3_db_filename(database, NULL) encoding:NSUTF8StringEncoding];
		RASqliteLog(@"Database `%@` is already open.", [filename lastPathComponent]);
	}
}

- (NSError *)close
{
	NSError *error;

	sqlite3 *database = [self database];
	if ( database != nil ) {
		int code = sqlite3_close(database);
		if ( code == SQLITE_OK ) {
			RASqliteLog(@"Database have been successfully closed.");
			[self setDatabase:nil];
		} else if ( code == SQLITE_BUSY ) {
			// TODO: Handle database with active statements.
			NSString *description = @"Database `%@` is currently busy and cannot be closed.";
			NSString *filename = [NSString stringWithCString:sqlite3_db_filename(database, NULL) encoding:NSUTF8StringEncoding];
			error = [self errorWithDescription:[NSString stringWithFormat:description, [filename lastPathComponent]] code:code];
		}
	} else {
		RASqliteLog(@"Database is already closed.");
	}

	return error;
}

- (NSError *)create
{
	NSError *error;

	NSDictionary *tables = [self structure];
	if ( tables != nil ) {
		for ( NSString *table in tables ) {
			error = [self createTable:table withColumns:[tables objectForKey:table]];
			if ( error != nil ) {
				break;
			}
		}
	} else {
		// TODO: Handle error code correctly.
		error = [self errorWithDescription:@"Unable to create database structure, none has been supplied." code:0];
	}

	return error;
}

- (NSError *)createTable:(NSString *)table withColumns:(NSDictionary *)columns
{
	NSError *error;

	if ( table == nil ) {
		// TODO: Handle error code correctly.
		error = [self errorWithDescription:@"Unable to create table without valid table name." code:0];
	}

	if ( columns == nil ) {
		// TODO: Handle error code correctly.
		error = [self errorWithDescription:@"Unable to create table without columns." code:0];
	}

	if ( [self error] == nil && error == nil ) {
		NSMutableString *sql = [[NSMutableString alloc] init];
		[sql appendFormat:@"CREATE TABLE IF NOT EXISTS %@(", table];

		unsigned int index = 0;
		for ( NSString *column in columns ) {
			if ( index > 0 ) {
				[sql appendString:@","];
			}
			[sql appendFormat:@"%@ ", column];

			NSString *type = [columns objectForKey:column];
			if ( [type isEqualToString:kRASqliteNull] ) {
				[sql appendString:type];
			} else if ( [type isEqualToString:kRASqliteInteger] ) {
				[sql appendString:type];

				if ( [column isEqualToString:@"id"] ) {
					[sql appendString:@" PRIMARY KEY"];
				} else {
					[sql appendString:@" DEFAULT 0"];
				}
			} else if ( [type isEqualToString:kRASqliteReal] ) {
				[sql appendString:type];
			} else if ( [type isEqualToString:kRASqliteText] ) {
				[sql appendString:type];
			} else if ( [type isEqualToString:kRASqliteBlob] ) {
				[sql appendString:type];
			} else {
				// TODO: Handle error code correctly.
				NSString *description = @"Unrecognized SQLite data type: %@";
				error = [self errorWithDescription:[NSString stringWithFormat:description, type] code:0];
				break;
			}

			index++;
		}
		[sql appendString:@");"];

		if ( error == nil ) {
			error = [self execute:sql];
		}
	}

	return error;
}

- (NSError *)deleteTable:(NSString *)table
{
	NSError *error;

	if ( table == nil ) {
		// TODO: Handle error code correctly.
		error = [self errorWithDescription:@"Unable to delete table without valid table name." code:0];
	}

	if ( [self error] == nil && error == nil ) {
		[self execute:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", table]];
	}

	return error;
}

- (NSError *)check
{
	NSError *error;

	NSDictionary *tables = [self structure];
	if ( tables != nil ) {
		for ( NSString *table in tables ) {
			error = [self checkTable:table withColumns:[tables objectForKey:table]];
			if ( error != nil ) {
				break;
			}
		}
	} else {
		// TODO: Handle error code correctly.
		error = [self errorWithDescription:@"Unable to check database structure, none has been supplied." code:0];
	}

	return error;
}

- (NSError *)checkTable:(NSString *)table withColumns:(NSDictionary *)columns
{
	NSError *error;

	if ( table == nil ) {
		// TODO: Handle error code correctly.
		error = [self errorWithDescription:@"Unable to check table without valid table name." code:0];
	}

	if ( columns == nil ) {
		// TODO: Handle error code correctly.
		error = [self errorWithDescription:@"Unable to check table without columns." code:0];
	}

	if ( [self error] == nil && error == nil ) {
		NSArray *tColumns = [self fetch:[NSString stringWithFormat:@"PRAGMA table_info(%@)", table]];

		if ( [tColumns count] == [columns count] ) {
			unsigned int index = 0;
			for ( NSString *column in columns ) {
				NSDictionary *tColumn = [tColumns objectAtIndex:index];
				if ( ![[tColumn objectForKey:@"name"] isEqualToString:column] ) {
					// TODO: Handle error code correctly.
					NSString *description = @"Column name `%@` do not match index `%i` for the given structure.";
					error = [self errorWithDescription:[NSString stringWithFormat:description, column, index] code:0];
					break;
				}

				NSString *type = [columns objectForKey:column];
				if ( ![[tColumn objectForKey:@"type"] isEqualToString:type] ) {
					// TODO: Handle error code correctly.
					NSString *description = @"Column type `%@` do not match index `%i` for the given structure.";
					error = [self errorWithDescription:[NSString stringWithFormat:description, type, index] code:0];
					break;
				}
				index++;
			}
		} else {
			// TODO: Handle error code correctly.
			error = [self errorWithDescription:@"Number of specified columns do not match table columns." code:0];
		}
	}

	return error;
}

- (NSError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement
{
	NSError *error;

	unsigned int index = 1;
	for ( id column in columns ) {
		if ( [column isKindOfClass:[NSString class]] ) {
			sqlite3_bind_text(*statement, index, [column UTF8String], -1, SQLITE_TRANSIENT);
		} else if ( [column isKindOfClass:[NSNumber class]] ) {
			const char *type = [column objCType];
			if ( strncmp(type, "i", 1) == 0 ) {
				sqlite3_bind_int(*statement, index, [column intValue]);
			} else if ( strncmp(type, "d", 1) == 0 || strncmp(type, "f", 1) == 0 ) {
				// Both double and float should be binded as double.
				sqlite3_bind_double(*statement, index, [column doubleValue]);
			} else if ( strncmp(type, "c", 1) == 0 || strncmp(type, "s", 1) == 0 ) {
				// Characters (both signed and unsigned) and bool values should
				// just be binded as an integer.
				sqlite3_bind_int(*statement, index, [column intValue]);
			} else {
				// TODO: Handle error code correctly.
				NSString *description = @"Unrecognized type of NSNumber: %s";
				error = [self errorWithDescription:[NSString stringWithFormat:description, type] code:0];
				break;
			}
		} else {
			// TODO: Implement support for more object types.
			// TODO: Handle error code correctly.
			NSString *description = @"Incomplete implementation of `bindColumns:toStatement:` for type: %@";
			error = [self errorWithDescription:[NSString stringWithFormat:description, [column class]] code:0];
			break;
		}
		index++;
	}

	return error;
}

- (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement
{
	unsigned int columnCount = sqlite3_column_count(*statement);
	NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:columnCount];

	// If an error occures within the loop the value for row will be changed to `nil`.
	for ( int index = 0; row != nil && index < columnCount; index++ ) {
		const char *name = sqlite3_column_name(*statement, index);
		NSString *column = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

		int type = sqlite3_column_type(*statement, index);
		switch ( type ) {
			case SQLITE_INTEGER: {
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
				// TODO: Handle the SQLITE_BLOB.
				// TODO: Handle error code correctly.
				[self setError:[self errorWithDescription:@"Incomplete implementation of `fetchColumns:` for `SQLITE_BLOB`." code:0]];
				row = nil;
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
	
	return row;
}

- (NSArray *)fetch:(NSString *)sql
{
	return [self fetch:sql withParams:nil];
}

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params
{
	if ( nil == [self database] ) {
		[self open];
	}

	NSMutableArray *results;

	if ( [self error] == nil ) {
		sqlite3_stmt *statement;
		int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

		if ( code == SQLITE_OK ) {
			if ( params != nil ) {
				[self setError:[self bindColumns:params toStatement:&statement]];
			}

			if ( [self error] == nil ) {
				// TODO: Better error handling, incase something is wrong.
				results = [[NSMutableArray alloc] initWithCapacity:[params count]];
				while ( sqlite3_step(statement) == SQLITE_ROW ) {
					NSDictionary *row = [self fetchColumns:&statement];
					[results addObject:row];
				}
			} else {
				// Reset the result value.
				results = nil;
			}
			sqlite3_finalize(statement);
		} else {
			NSString *description = @"An error occured when trying to `fetch:withParams`: `%s`";
			[self setError:[self errorWithDescription:[NSString stringWithFormat:description, sqlite3_errmsg([self database])] code:code]];

			// Reset the result value.
			results = nil;
		}
	}

	return results;
}

- (NSDictionary *)fetchRow:(NSString *)sql
{
	return [self fetchRow:sql withParams:nil];
}

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params
{
	if ( nil == [self database] ) {
		[self open];
	}

	NSDictionary *results;

	if ( [self error] == nil ) {
		sqlite3_stmt *statement;
		int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

		if ( code == SQLITE_OK ) {
			if ( params != nil ) {
				[self setError:[self bindColumns:params toStatement:&statement]];
			}

			if ( [self error] == nil ) {
				code = sqlite3_step(statement);
				if ( code == SQLITE_ROW ) {
					results = [self fetchColumns:&statement];
				} else {
					NSString *description = @"Failed to retrieve row: `%s`";
					[self setError:[self errorWithDescription:[NSString stringWithFormat:description, sqlite3_errmsg([self database])] code:code]];

					// Reset the result value.
					results = nil;
				}
			} else {
				// Reset the result value.
				results = nil;
			}
			sqlite3_finalize(statement);
		} else {
			NSString *description = @"An error occured when trying to `fetchRow:withParams`: `%s`";
			[self setError:[self errorWithDescription:[NSString stringWithFormat:description, sqlite3_errmsg([self database])] code:code]];

			// Reset the result value.
			results = nil;
		}
	}

	return results;
}

- (NSError *)execute:(NSString *)sql
{
	return [self execute:sql withParams:nil];
}

- (NSError *)execute:(NSString *)sql withParams:(NSArray *)params
{
	NSError *error;

	if ( nil == [self database] ) {
		[self open];
	}

	if ( [self error] == nil ) {
		sqlite3_stmt *statement;
		int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

		if ( code == SQLITE_OK ) {
			if ( params != nil ) {
				error = [self bindColumns:params toStatement:&statement];
			}

			if ( error == nil ) {
				code = sqlite3_step(statement);
				if ( code != SQLITE_DONE ) {
					NSString *description = @"Unable to execute query: `%s`";
					error = [self errorWithDescription:[NSString stringWithFormat:description, sqlite3_errmsg([self database])] code:code];
				}
			}
			sqlite3_finalize(statement);
		} else {
			NSString *description = @"An error occured when trying to `execute:withParams`: `%s`";
			error = [self errorWithDescription:[NSString stringWithFormat:description, sqlite3_errmsg([self database])] code:code];
		}
	}

	return error;
}

- (NSError *)errorWithDescription:(NSString *)description code:(NSInteger)code
{
	RASqliteLog(@"%@ (%i)", description, code);

	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"RASqlite Error" code:code userInfo:userInfo];
}

@end