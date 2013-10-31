//
//  RASqliteQueue.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-31.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

// -- -- RASqlite

#import "RASqlite.h"

@interface RASqliteQueue : NSObject {
/**
 Queue on which the queries will be executing.
 */
@protected dispatch_queue_t _queue;

@protected RASqlite *_db;
}

@property (nonatomic, readonly, strong) RASqlite *db;

@end