//
//  RAUserModel.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import "RASqlite.h"

@interface RAUserModel : RASqlite

- (NSArray *)getUsers;

- (void)addUser:(NSString *)username;

- (void)removeUser:(NSNumber *)userId;

@end