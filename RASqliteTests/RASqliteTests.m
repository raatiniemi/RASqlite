//
//  RASqliteTests.m
//  RASqliteTests
//
//  Created by Tobias Raatiniemi on 2013-11-30.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RASqlite.h"

/**
 Unit test for RASqlite.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqliteTests : XCTestCase

#pragma mark - Initialization

/**
 Test the initialization with `init`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testInit;

/**
 Initialization successful test with `initWithPath:`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testInitWithPathSuccess;

/**
 Initialization failure test with `initWithPath:`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testInitWithPathFailure;

@end

@implementation RASqliteTests

#pragma mark - Setup/teardown

- (void)setUp
{
	[super setUp];
}

- (void)tearDown
{
	[super tearDown];
}

#pragma mark - Initialization

- (void)testInit
{
	XCTAssertThrows([[RASqlite alloc] init], @"Use of the `init` method is not allowed, use `initWithName:` instead.");
}

- (void)testInitWithPathSuccess
{
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:@"/tmp/db"];
	XCTAssertNotNil(rasqlite, @"Database initialization failed with directory `/tmp`.");
}

- (void)testInitWithPathFailure
{
	// Database initialization should not be successful with readonly directories
	// since the `checkPath:` method checks permissions, among other things.
	XCTAssertThrows([[RASqlite alloc] initWithPath:@"/db"], @"Database initilization was successful with the readonly directory `/`.");
}

@end