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
		RASqlite *database = [[RASqlite alloc] initWithName:@"user.db"];

		// TODO: Check table structure and create it, if necessary.

		NSDictionary *user = [database fetchRow:@"SELECT id FROM users WHERE name = ? LIMIT 1" withParam:@"raatiniemi"];

		// Check if we were able to find the specified user.
		if ( user ) {
			// User have been found, time to do something with it.
			BOOL success = NO;
			success = [database execute:@"DELETE FROM users WHERE id = ?" withParam:[user objectForKey:@"id"]];

			// Check if the user could be removed.
			if ( success ) {
				NSLog(@"User have been removed.");

				// Check if there are any users left.
				NSArray *users = [database fetch:@"SELECT id, name FROM users"];
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
			BOOL success = [database execute:@"INSERT INTO users(name) VALUES(?)" withParam:@"raatiniemi"];
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