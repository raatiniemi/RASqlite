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
			RASqliteLog(@"Database have been successfully opened.");
			[self setDatabase:database];
		} else {
			NSString *description = [NSString stringWithFormat:@"Unable to open database: `%s`", sqlite3_errmsg([self database])];
			[self setError:[self errorWithDescription:description code:code]];
		}
	} else {
		RASqliteLog(@"Database `%s` is already open.", sqlite3_db_filename([self database], NULL));
	}
}

- (NSError *)close
{
	NSError *error;

	if ( [self database] != nil ) {
		int code = sqlite3_close([self database]);
		if ( code == SQLITE_OK ) {
			RASqliteLog(@"Database have been successfully closed.");
			[self setDatabase:nil];
		} else if ( code == SQLITE_BUSY ) {
			// TODO: Handle database with active statements.
			// TODO: Handle error code correctly.
			error = [self errorWithDescription:@"Database is currently busy and cannot be closed." code:0];
		}
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
		error = [self errorWithDescription:@"No structure have been supplied for the database." code:0];
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
				NSString *message = [NSString stringWithFormat:@"Unrecognized SQLite data type: %@", type];
				error = [self errorWithDescription:message code:0];
				break;
			}

			index++;
		}
		[sql appendString:@");"];

		if ( error == nil ) {
			[self execute:sql];
		}
	}

	return error;
}

- (void)deleteTable:(NSString *)table
{
	if ( table == nil ) {
		// TODO: Handle error.
	}

	if ( [self error] == nil ) {
		[self execute:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", table]];
	}
}

- (void)check
{
	NSDictionary *tables = [self structure];
	if ( tables != nil ) {
		for ( NSString *table in tables ) {
			[self checkTable:table withColumns:[tables objectForKey:table]];
		}
	} else {
		// TODO: Handle non-existing structure.
	}
}

- (void)checkTable:(NSString *)table withColumns:(NSDictionary *)columns
{
	if ( table == nil ) {
		// TODO: Handle error.
	}

	if ( columns == nil ) {
		// TODO: Handle error.
	}

	if ( [self error] == nil ) {
		NSArray *tColumns = [self fetch:[NSString stringWithFormat:@"PRAGMA table_info(%@)", table]];

		if ( [tColumns count] == [columns count] ) {
			unsigned int index = 0;
			for ( NSString *column in columns ) {
				NSDictionary *tColumn = [tColumns objectAtIndex:index];
				if ( ![[tColumn objectForKey:@"name"] isEqualToString:column] ) {
					// TODO: Properly handle column missmatch.
					NSLog(@"Column missmatch");
					break;
				}

				NSString *type = [columns objectForKey:column];
				if ( ![[tColumn objectForKey:@"type"] isEqualToString:type] ) {
					// TODO: Properly handle column missmatch.
					NSLog(@"Column data type missmatch");
					break;
				}
				index++;
			}
		}
	}
}

- (void)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement
{
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
				RASqliteLog(@"Unrecognized type for NSNumber: %s", type);
				break;
			}
		} else {
			// TODO: Implement support for more object types.
			RASqliteLog(@"Incomplete implementation of `bindColumns:toStatement:` for type: %@", [column class]);
			break;
		}
		index++;
	}
}

- (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement
{
	unsigned int columnCount = sqlite3_column_count(*statement);
	NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:columnCount];

	for ( int index = 0; index < columnCount; index++ ) {
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
				RASqliteLog(@"Incomplete implementation of `fetchColumns:` for `SQLITE_BLOB`.");
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
				[self bindColumns:params toStatement:&statement];
			}

			// TODO: Better error handling, incase something is wrong.
			results = [[NSMutableArray alloc] initWithCapacity:[params count]];
			while ( sqlite3_step(statement) == SQLITE_ROW ) {
				NSDictionary *row = [self fetchColumns:&statement];
				[results addObject:row];
			}
			sqlite3_finalize(statement);
		} else {
			// TODO: Better error handling.
			NSLog(@"An error occurred: %s (%i)", sqlite3_errmsg([self database]), code);
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
				[self bindColumns:params toStatement:&statement];
			}

			if ( sqlite3_step(statement) == SQLITE_ROW ) {
				results = [self fetchColumns:&statement];
			} else {
				// TODO: Better error handling.
				NSLog(@"Failed to retrieve row");
			}
			sqlite3_finalize(statement);
		} else {
			// TODO: Better error handling.
			NSLog(@"An error occurred: %s (%i)", sqlite3_errmsg([self database]), code);
		}
	}

	return results;
}

- (void)execute:(NSString *)sql
{
	[self execute:sql withParams:nil];
}

- (void)execute:(NSString *)sql withParams:(NSArray *)params
{
	if ( nil == [self database] ) {
		[self open];
	}

	if ( [self error] == nil ) {
		sqlite3_stmt *statement;
		int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

		if ( code == SQLITE_OK ) {
			if ( params != nil ) {
				[self bindColumns:params toStatement:&statement];
			}

			if ( sqlite3_step(statement) != SQLITE_DONE ) {
				// TODO: Better error handling.
				NSLog(@"Unable to execute query");
			}
			sqlite3_finalize(statement);
		} else {
			// TODO: Better error handling.
			NSLog(@"An error occurred: %s (%i)", sqlite3_errmsg([self database]), code);
		}
	}
}

- (NSError *)errorWithDescription:(NSString *)description code:(NSInteger)code
{
	RASqliteLog(@"%@ (%i)", description, code);

	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"RASqlite Error" code:code userInfo:userInfo];
}

@end