//
//  RASqliteModel.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RASqliteModel.h"

static sqlite3 *_database;

@interface RASqliteModel () {
@private NSString *_name;
}

@property (nonatomic, readwrite, strong) NSString *name;

#pragma mark - Database

- (void)setDatabase:(sqlite3 *)database;

- (NSString *)path;

@end

@implementation RASqliteModel

@synthesize name = _name;

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
	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [NSString stringWithFormat:@"%@/%@", [directories objectAtIndex:0], [self name]];
}

- (BOOL)openWithFlags:(int)flags
{
	BOOL __block open = NO;

	dispatch_sync(_queue, ^{
		sqlite3 *database = [self database];
		if ( !database ) {
			int code = sqlite3_open_v2([[self path] UTF8String], &database, flags, NULL);
			if ( code == SQLITE_OK ) {
				// TODO: Debug message, database have successfully been opened.
				NSLog(@"Database have successfully been opened.");

				[self setDatabase:database];
				open = YES;
			} else {
				// TODO: Failed to open database, handle error.
				NSLog(@"Database failed to open with code: %i", code);
			}
		} else {
			// TODO: Debug message, database is already open.
			NSLog(@"Database is already open.");

			open = YES;
		}
	});

	return open;
}

- (BOOL)open
{
	return [self openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE];
}

- (BOOL)close
{
	BOOL __block close = NO;

	dispatch_sync(_queue, ^{
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
					// TODO: Failed to close database, handle error.
					NSLog(@"Database failed to close with code: %i", code);
				} else {
					// TODO: Debug message, database have successfully been closed.
					NSLog(@"Database have successfully been closed.");

					[self setDatabase:nil];
					close = YES;
				}
			} while (retry);
		} else {
			// TODO: Debug message, database is already closed.
			NSLog(@"Database is already closed.");

			close = YES;
		}
	});

	return close;
}

@end