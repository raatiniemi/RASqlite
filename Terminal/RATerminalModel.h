//
//  RATerminalModel.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-04.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

// -- -- RASqlite

#import "RASqlite.h"

/**
 Model for working with the sample user database.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RATerminalModel : RASqlite

- (NSDictionary *)getUser:(NSString *)name;

- (NSArray *)getUsers;

- (BOOL)addUser:(NSString *)name;

- (BOOL)removeUser:(NSNumber *)userId;

@end