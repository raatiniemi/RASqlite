//
// Created by Tobias Raatiniemi on 2016-11-04.
// Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSDictionary+RASqlite.h"

@interface NSDictionary_RASqliteTests : XCTestCase

- (void)testGetColumn_withoutKey;

- (void)testGetColumn_withKey;

- (void)testHasColumn_withoutKey;

- (void)testHasColumn_withKey;

@end

@implementation NSDictionary_RASqliteTests

- (void)testGetColumn_withoutKey {
    NSDictionary *dictionary = @{};

    XCTAssertEqual([NSNull null], [dictionary getColumn:@"null"]);
}

- (void)testGetColumn_withKey {
    NSDictionary *dictionary = @{@"foo": @"bar"};

    XCTAssertEqual(@"bar", [dictionary getColumn:@"foo"]);
}

- (void)testHasColumn_withoutKey {
    NSDictionary *dictionary = @{};

    XCTAssertFalse([dictionary hasColumn:@"null"]);
}

- (void)testHasColumn_withKey {
    NSDictionary *dictionary = @{@"foo": @"bar"};

    XCTAssertTrue([dictionary hasColumn:@"foo"]);
}

@end
