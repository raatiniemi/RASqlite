//
// Created by Tobias Raatiniemi on 2016-11-04.
// Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSMutableDictionary+RASqlite.h"

@interface NSMutableDictionary_RASqliteTests : XCTestCase

- (void)testSetColumnWithObject_withNil;

- (void)testSetColumnWithObject_withObject;

@end

@implementation NSMutableDictionary_RASqliteTests

- (void)testSetColumnWithObject_withNil {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setColumn:@"foo" withObject:nil];

    XCTAssertEqual(dictionary[@"foo"], [NSNull null]);
}

- (void)testSetColumnWithObject_withObject {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setColumn:@"foo" withObject:@"bar"];

    XCTAssertEqual(dictionary[@"foo"], @"bar");
}

@end
