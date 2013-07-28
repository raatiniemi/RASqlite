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

- (NSArray *)getUsers
{
	return [self fetch:@"SELECT id, username FROM users"];
}

- (void)addUser:(NSString *)username
{
	NSArray *params = [NSArray arrayWithObject:username];
	[self execute:@"INSERT INTO users(username) VALUES(?)" withParams:params];
}

- (void)removeUser:(NSNumber *)userId
{
	NSArray *params = [NSArray arrayWithObject:userId];
	[self execute:@"DELETE FROM users WHERE id = ?" withParams:params];
}

@end