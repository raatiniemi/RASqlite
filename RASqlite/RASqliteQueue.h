//
//  RASqliteQueue.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-15.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RASqliteQueue : NSObject

/**
 Get shared queue.

 This will be the default queue used when communicating with the database.

 @return Shared queue.
 */
+ (RASqliteQueue *)sharedQueue;

- (instancetype)init __unavailable;

/**
 Dispatch block on the queue.

 @param block Block to dispatch on the queue.
 */
- (void)dispatchBlock:(void (^)(void))block;

@end
