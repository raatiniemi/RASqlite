//
//  RASqliteQueue.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-15.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import "RASqliteQueue.h"

static RASqliteQueue *_sharedQueue = nil;

static char * const RASqliteQueueNameKey = "me.raatiniemi.rasqlite.queue.name";
static NSString * const RASqliteThreadFormat = @"me.raatiniemi.rasqlite.%@";

@interface RASqliteQueue ()

/**
 Instantiate queue with name.

 @param name Name of the queue.
 */
- (instancetype)initWithName:(NSString *)name;

@end

@implementation RASqliteQueue {
@private
    dispatch_queue_t _queue;
}

+ (RASqliteQueue *)sharedQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedQueue = [[RASqliteQueue alloc] initWithName:@"shared-queue"];
    });

    return _sharedQueue;
}

- (instancetype)initWithName:(NSString *)name {
    if (self = [super init]) {
        _queue = [self buildQueueWithName:name];
    }

    return self;
}

- (dispatch_queue_t)buildQueueWithName:(NSString *)name {
    const char *threadName = [[NSString stringWithFormat:RASqliteThreadFormat, name] UTF8String];
    dispatch_queue_t queue = dispatch_queue_create(threadName, NULL);
    // TODO: Generate better unique value.
    dispatch_queue_set_specific(queue, RASqliteQueueNameKey, (void *) threadName, NULL);

    return queue;
}

- (void)dispatchBlock:(void (^)(void))block {
    if (self.isInternalQueue) {
        block();
        return;
    }

    dispatch_sync(_queue, ^{
        block();
    });
}

- (BOOL)isInternalQueue {
    void *label = dispatch_get_specific(RASqliteQueueNameKey);

    return label == dispatch_queue_get_specific(_queue, RASqliteQueueNameKey);
}

@end
