//
//  RASqliteTests.m
//  RASqliteTests
//
//  Created by Tobias Raatiniemi on 2013-11-30.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RASqlite.h"

static NSString *_directory = @"/tmp/rasqlite";

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

/**
 Initialization successful test with `initWithName:`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 Since the `initWithName:` will just call the designated initializer, i.e.
 `initWithPath:`, there's no need to test the failure.
 */
- (void)testInitWithNameSuccess;

#pragma mark - Database

/**
 Open database with non-existing database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 Normally when the file do not exists, the file will be created but to test the
 functionality the `SQLITE_OPEN_CREATE` flag have been omitted.
 */
- (void)testOpenWithNonExistingFile;

/**
 Open database with existing database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testOpenWithExistingFile;

/**
 Open database, create database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testOpenCreateFile;

/**
 Attempt to open database with already open database.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testOpenAlreadyOpenDatabase;

#pragma mark -- Close

/**
 Attempt to close non-initialized database.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCloseNonInitializedDatabase;

#pragma mark - Table

#pragma mark -- Check

- (void)testCheckWithoutStructure;

// TODO: Test with structure with mock.

- (void)testCheckTableWithoutTable;

- (void)testCheckTableWithoutColumns;

- (void)testCheckNonExistingTable;

// TODO: Test check for number of columns, column order etc.

#pragma mark -- Create

@end

@implementation RASqliteTests

#pragma mark - Setup/teardown

- (void)setUp
{
	[super setUp];

	// Create the directory that will contain the unit test files.
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)tearDown
{
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager removeItemAtPath:_directory error:nil];

	[super tearDown];
}

#pragma mark - Initialization

- (void)testInit
{
	XCTAssertThrows([[RASqlite alloc] init], @"`init` method did not fail.");
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
	XCTAssertThrows([[RASqlite alloc] initWithPath:@"/db"],
					@"Database initilization was successful with the readonly directory `/`.");
}

- (void)testInitWithNameSuccess
{
	RASqlite *rasqlite = [[RASqlite alloc] initWithName:@"db"];
	XCTAssertNotNil(rasqlite, @"Database initialization failed with name `db`.");
}

#pragma mark - Database

#pragma mark -- Open

- (void)testOpenWithNonExistingFile
{
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:@"/tmp/none_existing_file"];
	XCTAssertNotNil([rasqlite openWithFlags:SQLITE_OPEN_READWRITE],
					@"Open database was successful with non existing file.");
}

- (void)testOpenWithExistingFile
{
	NSString *path = [_directory stringByAppendingString:@"/existing_file"];
	NSFileManager *manager = [NSFileManager defaultManager];
	[manager createFileAtPath:path contents:nil attributes:nil];

	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];
	XCTAssertNil([rasqlite openWithFlags:SQLITE_OPEN_READWRITE],
				 @"Open database was failed with existing file: %@", [[rasqlite error] localizedDescription]);
}

- (void)testOpenCreateFile
{
	NSString *path = [_directory stringByAppendingString:@"/create_file"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];
	XCTAssertNil([rasqlite openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE],
				 @"Open database with create failed: %@", [[rasqlite error] localizedDescription]);
}

- (void)testOpenAlreadyOpenDatabase
{
	NSString *path = [_directory stringByAppendingString:@"/open_database"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];
	XCTAssertNil([rasqlite open], @"Open database failed: %@", [[rasqlite error] localizedDescription]);
	XCTAssertNil([rasqlite open], @"Open already open database failed: %@", [[rasqlite error] localizedDescription]);
}

#pragma mark -- Close

- (void)testCloseNonInitializedDatabase
{
	NSString *path = [_directory stringByAppendingString:@"/closed_database"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];
	XCTAssertNil([rasqlite close],
				 @"Close non initialized database failed: %@", [[rasqlite error] localizedDescription]);
}

#pragma mark - Table

#pragma mark -- Check

- (void)testCheckWithoutStructure
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	// TODO: Figure out why `XCTAssertThrows` do not capture the exception.
	// XCTAssertThrows([rasqlite check], @"Unable to check database structure, none has been supplied.");
}

- (void)testCheckTableWithoutTable
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSDictionary *columns = @{@"id": RASqliteInteger};
	XCTAssertThrows([rasqlite checkTable:nil withColumns:columns],
					@"Check without table name did not throw exception.");
}

- (void)testCheckTableWithoutColumns
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	XCTAssertThrows([rasqlite checkTable:@"foo" withColumns:nil],
					@"Check without columns did not throw exception.");
}

- (void)testCheckNonExistingTable
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSDictionary *columns = @{@"id": RASqliteInteger};
	XCTAssertFalse([rasqlite checkTable:@"foo" withColumns:columns],
				   @"");
}

@end