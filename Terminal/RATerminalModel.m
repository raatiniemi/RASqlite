//
//  RATerminalModel.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-04.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RATerminalModel.h"

static sqlite3 *_database;

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
	NSMutableDictionary *user = [[NSMutableDictionary alloc] init];
	[user setObject:RASqliteInteger forKey:@"id"];
	[user setObject:RASqliteText forKey:@"name"];

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
		RASqliteLog(@"Database pointer rewrite attempt.");
	}
}

- (sqlite3 *)database
{
	return _database;
}

#pragma mark - Handle users

- (RASqliteRow *)getUser:(NSString *)name
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