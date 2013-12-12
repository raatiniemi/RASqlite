//
//  RATerminalModel.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-04.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
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
	if ( self = [super initWithName:@"user.db"] ) {
	}
	return self;
}

#pragma mark - Database

- (NSDictionary *)structure
{
	NSMutableArray *user = [[NSMutableArray alloc] init];
	RASqliteColumn *column;

	column = [[RASqliteColumn alloc] initWithName:@"id" type:RASqliteInteger];
	[column setAutoIncrement:YES];
	[column setPrimaryKey:YES];
	[user addObject:column];

	column = [[RASqliteColumn alloc] initWithName:@"name" type:RASqliteText];
	[column setUnique:YES];
	[user addObject:column];

	column = [[RASqliteColumn alloc] initWithName:@"email" type:RASqliteText];
	[column setNullable:YES];
	[user addObject:column];

	NSMutableDictionary *tabeller = [[NSMutableDictionary alloc] init];
	[tabeller setObject:user forKey:@"user"];

	return tabeller;
}

- (void)setDatabase:(sqlite3 *)database
{
	// Protection from rewriting the database pointer mid execution. The pointer
	// have to be resetted before setting a new instance.
	if ( _database == nil || database == nil ) {
		_database = database;
	} else {
		// Incase an rewrite have been attempted, this should be logged.
		RASqliteLog(RASqliteLogLevelWarning, @"Database pointer rewrite attempt.");
	}
}

- (sqlite3 *)database
{
	return _database;
}

#pragma mark - Queue

- (void)setQueue:(dispatch_queue_t)queue
{
	// Protection from rewriting the queue pointer mid execution. The pointer
	// have to be resetted before setting a new instance.
	if ( _queue == nil || queue == nil ) {
		_queue = queue;
	} else {
		// Incase an rewrite have been attempted, this should be logged.
		RASqliteLog(RASqliteLogLevelWarning, @"Queue pointer rewrite attempt.");
	}
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