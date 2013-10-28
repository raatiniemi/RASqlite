//
//  main.m
//  Terminal
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RASqlite.h"

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		RASqliteModel *model = [[RASqliteModel alloc] initWithName:@"user.db"];
		NSDictionary *user = [model fetchRow:@"SELECT id FROM users WHERE name = ? LIMIT 1" withParam:@"raatiniemi"];

		if ( user ) {
			if ( [model execute:@"DELETE FROM users WHERE id = ?" withParam:[user objectForKey:@"id"]] ) {
				NSLog(@"User could not be removed.");
			} else {
				NSLog(@"User have been removed.");

				NSArray *users = [model fetch:@"SELECT id, name FROM users"];
				if ( users != nil ) {
					if ( [users count] > 0 ) {
						NSLog(@"Users exists.");
					} else {
						NSLog(@"No users exists.");
					}
				} else {
					if ( [model error] ) {
						// Print the error message to the log and reset. If we do not
						// reset we'll be unable to perform any additional queries with
						// the instantiated model.
						NSLog(@"An error occurred: %@", [[model error] localizedDescription]);
						[model setError:nil];
					}
				}
			}
		} else {
			// Check if an error has occurred with the query.
			if ( [model error] ) {
				// Print the error message to the log and reset. If we do not
				// reset we'll be unable to perform any additional queries with
				// the instantiated model.
				NSLog(@"An error occurred: %@", [[model error] localizedDescription]);
				[model setError:nil];
			} else {
				if ( [model execute:@"INSERT INTO users(name) VALUES(?)" withParams:@[@"raatiniemi"]] ) {
					NSLog(@"User could not be created.");
				} else {
					NSLog(@"User have been created.");
				}
			}
		}
	}
    return 0;
}