//
//  RAUserModel.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import "RAUserModel.h"

static sqlite3 *user;

@implementation RAUserModel

- (id)init
{
	if ( self = [super initWithName:@"User.db"] ) {
	}
	return self;
}

- (sqlite3 *)database
{
	return user;
}

- (void)setDatabase:(sqlite3 *)database
{
	user = database;
}

- (NSDictionary *)structure
{
	NSMutableDictionary *users = [[NSMutableDictionary alloc] init];
	[users setObject:@"INTEGER" forKey:@"id"];
	[users setObject:@"TEXT" forKey:@"username"];

	NSMutableDictionary *tables = [[NSMutableDictionary alloc] init];
	[tables setObject:users forKey:@"Users"];

	return tables;
}

- (NSArray *)getUsers
{
	return [self fetch:@"SELECT id, username FROM Users"];
}

- (void)addUser:(NSString *)username
{
	[self beginTransaction];
	NSArray *params = [NSArray arrayWithObject:username];
	if ( [self execute:@"INSERT INTO Users(username) VALUES(?)" withParams:params] == nil ) {
		[self commit];
	} else {
		[self rollBack];
	}
}

- (void)removeUser:(NSNumber *)userId
{
	NSArray *params = [NSArray arrayWithObject:userId];
	[self execute:@"DELETE FROM Users WHERE id = ?" withParams:params];
}

@end