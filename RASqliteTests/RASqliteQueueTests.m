//
//  RASqliteQueueTests.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-15.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RASqliteQueue.h"

@interface RASqliteQueueTests : XCTestCase {
@private
    int _number;
}

@end

@implementation RASqliteQueueTests

#pragma mark - Setup/tear down

- (void)setUp {
    _number = 0;
}

#pragma mark - Test

- (void)test_incrementNumberFromMultipleThreads {
    NSMutableArray *operations = [@[] mutableCopy];
    for (int i = 0; i < 10000; i++) {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [[RASqliteQueue sharedQueue] dispatchBlock:^{
                int number = _number + 1;
                usleep(arc4random_uniform(100));

                _number = number;
            }];
        }];

        [operations addObject:operation];
    }
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:20];
    [queue addOperations:operations waitUntilFinished:YES];

    XCTAssertTrue(10000 == _number);
}

@end
