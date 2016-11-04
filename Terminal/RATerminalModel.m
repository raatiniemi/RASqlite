//
//  RATerminalModel.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-04.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import "RATerminalModel.h"

/**
 Instance for the database.

 @note
 Since we only want a single instance to the database in real application
 environments for each model, we have to declare the variable static.
 */
static sqlite3 *_database;

/**
 Instance for the queue.

 @note
 Since we only want a single queue to execute against the database, we have
 to declare the static variable. Otherwise we might get IO errors or memory
 issues when accessing/writing to the database from several threads.
 */
static dispatch_queue_t _queue;

@implementation RATerminalModel

#pragma mark - Initialization

- (id)init
{
	if ( self = [super initWithPath:@"/tmp/rasqlite-user.db"] ) {
		[self queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
			// Iterate over the table structure.
			for ( NSString *table in [self structure] ) {
				NSArray *columns = [[self structure] objectForKey:table];

				// Check if the structure for the table have changed.
				if ( !( *commit = [db checkTable:table withColumns:columns] ) ) {
					// The structure have changed, delete the table and
					// recreate it with the new column structure.
					*commit = [db deleteTable:table];
					if ( *commit ) {
						*commit = [db createTable:table withColumns:columns];
					}
				}

				// If either of the operations fails the transaction is failed.
				if ( !*commit ) {
					break;
				}
			}
		}];
	}
	return self;
}

#pragma mark - Database

- (NSDictionary *)structure
{
	NSMutableArray *user = [[NSMutableArray alloc] init];
	RASqliteColumn *column;

	column = RAColumn(@"id", RASqliteInteger);
	[column setAutoIncrement:YES];
	[column setPrimaryKey:YES];
	[user addObject:column];

	column = RAColumn(@"name", RASqliteText);
	[user addObject:column];

	column = RAColumn(@"email", RASqliteText);
	[column setNullable:YES];
	[user addObject:column];

	column = RAColumn(@"level", RASqliteInteger);
	[column setDefaultValue:@1];
	[user addObject:column];

	NSMutableDictionary *tabeller = [[NSMutableDictionary alloc] init];
	[tabeller setObject:user forKey:@"user"];

	return tabeller;
}

- (void)setDatabase:(sqlite3 *)database
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_database = database;
	});
}

- (sqlite3 *)database
{
	return _database;
}

#pragma mark - Queue

- (void)setQueue:(dispatch_queue_t)queue
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_queue = queue;
	});
}

- (dispatch_queue_t)queue
{
	return _queue;
}

#pragma mark - Handle users

- (NSDictionary *)getUser:(NSString *)name
{
	return [self fetchRow:@"SELECT id FROM user WHERE name = ? LIMIT 1" withParam:name];
}

- (NSArray *)getUsers
{
	return [self fetch:@"SELECT id, name FROM user"];
}

- (BOOL)addUser:(NSString *)name
{
	return [self execute:@"INSERT INTO user(name) VALUES(?)" withParam:name];
}

- (BOOL)removeUser:(NSNumber *)userId
{
	return [self execute:@"DELETE FROM user WHERE id = ?" withParam:userId];
}

@end