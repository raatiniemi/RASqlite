//
//  main.m
//  Terminal
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RATerminalModel.h"

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		RATerminalModel *model = [[RATerminalModel alloc] initWithName:@"user.db"];
		[model queueWithBlock:^(RASqlite *db) {
			if ( ![db check] ) {
				[db create];
			}
		}];

		// Check if we were able to find the specified user.
		NSDictionary *user = [model getUser:@"raatiniemi"];
		if ( user ) {
			// User have been found, time to do something with it.
			BOOL success = NO;
			success = [model removeUser:[user getColumn:@"id"]];

			// Check if the user could be removed.
			if ( success ) {
				NSLog(@"User have been removed.");

				// Check if there are any users left.
				NSArray *users = [model getUsers];
				if ( [users count] > 0 ) {
					NSLog(@"Users still exists.");
				} else if ( ![model error] ) {
					NSLog(@"No users exists.");
				} else {
					// We have to reset the error variable, if an error occurres,
					// after we have handled it. Otherwise, the database instance
					// won't be able to execute any more queries.
					[model setError:nil];
				}
			} else {
				NSLog(@"User could not be removed.");

				// We have to reset the error variable, if an error occurres,
				// after we have handled it. Otherwise, the database instance
				// won't be able to execute any more queries.
				[model setError:nil];
			}
		} else if ( ![model error] ) {
			// No user were found, we should create it.
			BOOL success = [model addUser:@"raatiniemi"];
			if ( success ) {
				NSLog(@"User have been created.");
			} else {
				NSLog(@"User could not be created.");

				// We have to reset the error variable, if an error occurres,
				// after we have handled it. Otherwise, the database instance
				// won't be able to execute any more queries.
				[model setError:nil];
			}
		} else {
			// We have to reset the error variable, if an error occurres, after
			// we have handled it. Otherwise, the database instance won't be able
			// to execute any more queries.
			[model setError:nil];
		}
		[model close];
	}
    return 0;
}