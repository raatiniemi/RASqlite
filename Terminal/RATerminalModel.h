//
//  RATerminalModel.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-04.
//  Copyright (c) 2013-2014 Raatiniemi. All rights reserved.
//

// -- -- RASqlite

#import "RASqlite.h"
#import "RASqlite+RASqliteTable.h"

/**
 Model for working with the sample user database.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RATerminalModel : RASqlite

/**
 Get the user information based on the username.

 @param name Name for the user.

 @return Information for the user.

 @code
 @{@"id"}
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSDictionary *)getUser:(NSString *)name;

/**
 Retrieve all of the registered users.

 @return List of registered users.

 @code
 @{@"id", @"name"}
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSArray *)getUsers;

/**
 Add a new user to the registry.

 @param name Name for the user.

 @return `YES` if user was successfully registered, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)addUser:(NSString *)name;

/**
 Remove user based on the users id.

 @param userId Id for the user to remove.

 @return `YES` if user is removed successfully, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)removeUser:(NSNumber *)userId;

@end