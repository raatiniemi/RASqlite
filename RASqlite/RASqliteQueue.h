//
//  RASqliteQueue.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-31.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

// -- -- Constants

/**
 Format for the name of the query threads.
 */
#define kRASqliteThreadFormat @"me.raatiniemi.rasqlite.%@"

// -- -- RASqlite

// TODO: Find a way around the @class-directive.
// Because RASqlite.h includes RASqliteQueue.h, which should include RASqlite.h
// references to RASqlite within RASqliteQueue.h will fail, or point to an int.
@class RASqlite;

@interface RASqliteQueue : NSObject {
@protected dispatch_queue_t _queue;
}

#pragma mark - Initialization

/**
 Initialize the database queue with the database.

 @param database Instance of the database.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (instancetype)initWithDatabase:(RASqlite *)database;

#pragma mark - Execute

/**
 Execute a block within the query thread.

 @param block Block to be executed.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)queueWithBlock:(void (^)(RASqlite *db))block;

- (void)transactionType:(NSInteger)type withBlock:(void (^)(RASqlite *db, BOOL *commit))block;

- (void)transactionWithBlock:(void (^)(RASqlite *db, BOOL *commit))block;

@end