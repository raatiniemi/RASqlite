//
//  RASqlite+RASqliteHelper.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-05-25.
//  Copyright (c) 2014 Raatiniemi. All rights reserved.
//

#import "RASqlite+RASqliteHelper.h"

@implementation RASqlite (RASqliteHelper)

- (NSNumber *)lastInsertId
{
	NSNumber __block *insertId;
	if ( ![self error] && [self database] ) {
		[self queueWithBlock:^(RASqlite *db) {
			insertId = @(sqlite3_last_insert_rowid([self database]));
		}];
	}

	return insertId;
}

- (NSNumber *)rowCount
{
	NSNumber __block *count;
	if ( ![self error] && [self database] ) {
		[self queueWithBlock:^(RASqlite *db) {
			count = @(sqlite3_changes([self database]));
		}];
	}

	return count;
}

@end