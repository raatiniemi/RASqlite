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
			NSLog(@"Database has been opened.");

			[self setDatabase:database];
		} else {
			// TODO: Better error handling.
			NSLog(@"An error has occurred when attempting to open the database: %s (%i)", sqlite3_errmsg([self database]), code);
		}
	} else {
		NSLog(@"Database is already open!");
	}
}

- (void)close
{
	if ( [self database] != nil ) {
		int code = sqlite3_close([self database]);
		if ( code == SQLITE_OK ) {
			[self setDatabase:nil];
		} else if ( code == SQLITE_BUSY ) {
			// TODO: Handle database with active statements.
		}
	}
}

- (void)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement
{
	if ( [columns count] > 0 ) {
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
					NSLog(@"Unhandled NSNumber type: %s", type);
				}
			}
			index++;
		}
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
				// TODO: Handle blob type.
				NSLog(@"Unhandled column type.");
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
			NSLog(@"An error occurred, retrieved code: %s (%i)", sqlite3_errmsg([self database]), code);
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
			NSLog(@"An error occurred, retrieved code: %s (%i)", sqlite3_errmsg([self database]), code);
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
			NSLog(@"An error occurred, retrieved code: %s (%i)", sqlite3_errmsg([self database]), code);
		}
	}
}

@end