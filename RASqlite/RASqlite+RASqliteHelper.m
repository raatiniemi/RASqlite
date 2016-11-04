//
//  RASqlite+RASqliteHelper.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-05-25.
//  Copyright (c) 2014-2016 Raatiniemi. All rights reserved.
//

#import "RASqlite+RASqliteHelper.h"

@implementation RASqlite (RASqliteHelper)

- (NSNumber *)lastInsertId
{
	NSNumber __block *insertId;

	[self queueWithBlock:^(RASqlite *db) {
		if ( [db database] ) {
			insertId = @(sqlite3_last_insert_rowid([db database]));
		}
	}];

	return insertId;
}

- (NSNumber *)rowCount
{
	NSNumber __block *count;

	[self queueWithBlock:^(RASqlite *db) {
		if ( [db database] ) {
			count = @(sqlite3_changes([db database]));
		}
	}];

	return count;
}

@end