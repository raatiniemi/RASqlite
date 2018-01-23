//
//  RASqlite_ConcurrencyTests.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-15.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RASqlite.h"
#import "RASqlite+RASqliteTable.h"

static NSString * const _databasePath = @"/tmp/rasqlite/concurrency";

@interface RASqlite_ConcurrencyTests : XCTestCase {
@private
    RASqlite *_rasqlite;
}

@end

@implementation RASqlite_ConcurrencyTests

#pragma mark - Helper

- (RASqliteColumn *)buildColumnWithName:(NSString *)name andType:(RASqliteDataType)type {
    RASqliteColumn *column = RAColumn(name, type);
    column.nullable = YES;

    return column;
}

#pragma mark - Setup/tear down

- (void)setUp {
    [super setUp];

    _rasqlite = [[RASqlite alloc] initWithPath:_databasePath];
    [_rasqlite createTable:@"concurrency"
               withColumns:@[
                       [self buildColumnWithName:@"number" andType:RASqliteInteger]
               ]];
}

- (void)tearDown {
    [NSFileManager.defaultManager removeItemAtPath:_databasePath error:nil];

    [super tearDown];
}

#pragma mark - Test

- (void)test_incrementNumberFromMultipleThreads {
    NSMutableArray *operations = [@[] mutableCopy];
    for (int i = 0; i < 1000; i++) {
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [_rasqlite queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
                NSDictionary *row = [db fetchRow:@"SELECT number FROM concurrency"];
                usleep(arc4random_uniform(100));

                if (nil == row) {
                    *commit = [db execute:@"INSERT INTO concurrency (number) VALUES (?)" withParam:@(1)];
                    return;
                }
                *commit = [db execute:@"UPDATE concurrency SET number = number + 1 LIMIT 1"];
            }];
        }];

        [operations addObject:operation];
    }
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:20];
    [queue addOperations:operations waitUntilFinished:YES];

    NSArray<NSDictionary *> *rows = [_rasqlite fetch:@"SELECT number FROM concurrency"];
    XCTAssertTrue(1 == [rows count]);
    XCTAssertTrue(1000 == [rows[0][@"number"] integerValue]);
}

@end
