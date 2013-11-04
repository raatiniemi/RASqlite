//
//  RATerminalModel.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-04.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RATerminalModel.h"

@implementation RATerminalModel

- (NSDictionary *)structure
{
	NSMutableDictionary *user = [[NSMutableDictionary alloc] init];
	[user setObject:kRASqliteInteger forKey:@"id"];
	[user setObject:kRASqliteText forKey:@"name"];

	NSMutableDictionary *tabeller = [[NSMutableDictionary alloc] init];
	[tabeller setObject:user forKey:@"user"];

	return tabeller;
}

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