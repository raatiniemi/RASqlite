//
//  main.m
//  Terminal
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

// -- -- RASqlite

#import "RASqlite.h"

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		// TODO: References from the queue to the database error object?
		// As of now the database have to be around any time a query will be
		// executed to get the error message, if any occurred.

		RASqlite *database = [[RASqlite alloc] initWithName:@"user.db"];
		RASqliteQueue *queue = [[RASqliteQueue alloc] initWithDatabase:database];

		// TODO: Check table structure and create it, if necessary.

		NSDictionary __block *user;
		[queue queueWithBlock:^(RASqlite *db) {
			user = [db fetchRow:@"SELECT id FROM users WHERE name = ? LIMIT 1" withParam:@"raatiniemi"];
		}];

		// Check if we were able to find the specified user.
		if ( user ) {
			// User have been found, time to do something with it.
			BOOL __block success = NO;
			[queue queueWithBlock:^(RASqlite *db) {
				success = [db execute:@"DELETE FROM users WHERE id = ?" withParam:[user objectForKey:@"id"]];
			}];

			// Check if the user could be removed.
			if ( success ) {
				NSLog(@"User have been removed.");

				NSArray __block *users;
				[queue queueWithBlock:^(RASqlite *db) {
					users = [db fetch:@"SELECT id, name FROM users"];
				}];

				// Check if there are any users left.
				if ( users ) {
					NSLog(@"Users still exists.");
				} else if ( ![database error] ) {
					NSLog(@"No users exists.");
				} else {
					NSLog(@"An error occurred: %@", [[database error] localizedDescription]);

					// We have to reset the error variable, if an error occurres,
					// after we have handled it. Otherwise, the database instance
					// won't be able to execute any more queries.
					[database setError:nil];
				}
			} else {
				NSLog(@"User could not be removed.");
				NSLog(@"An error occurred: %@", [[database error] localizedDescription]);

				// We have to reset the error variable, if an error occurres,
				// after we have handled it. Otherwise, the database instance
				// won't be able to execute any more queries.
				[database setError:nil];
			}
		} else if ( ![database error] ) {
			// No user were found, we should create it.
			BOOL __block success = NO;
			[queue queueWithBlock:^(RASqlite *db) {
				success = [db execute:@"INSERT INTO users(name) VALUES(?)" withParam:@"raatiniemi"];
			}];

			if ( success ) {
				NSLog(@"User have been created.");
			} else {
				NSLog(@"User could not be created.");
				NSLog(@"An error occurred: %@", [[database error] localizedDescription]);

				// We have to reset the error variable, if an error occurres,
				// after we have handled it. Otherwise, the database instance
				// won't be able to execute any more queries.
				[database setError:nil];
			}
		} else {
			// An error occurred and we couldn't retrieve the user, handle it.
			NSLog(@"An error occurred: %@", [[database error] localizedDescription]);

			// We have to reset the error variable, if an error occurres, after
			// we have handled it. Otherwise, the database instance won't be able
			// to execute any more queries.
			[database setError:nil];
		}
	}
    return 0;
}