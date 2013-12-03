//
//  RASqliteTests.m
//  RASqliteTests
//
//  Created by Tobias Raatiniemi on 2013-11-30.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RASqlite.h"

/// Base directory for the unit test databases.
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

/**
 Attempt to check table without structure.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckWithoutStructure;

// TODO: Test with structure with mock.

/**
 Attempt to check table without table name.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithoutTable;

/**
 Attempt to check table without columns.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithoutColumns;

/**
 Attempt to check non-existing table.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckNonExistingTable;

// TODO: Test check for number of columns, column order etc.

#pragma mark -- Create

/**
 Attempt to create table without structure.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateWithoutStructure;

// TODO: Test with structure with mock.

/**
 Attempt to create table without table name.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateTableWithoutTable;

/**
 Attempt to create table without columns.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateTableWithoutColumns;

/**
 Attempt to create table with available data types.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateTable;

/**
 Attempt to create table with null data type.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateTableWithNullType;

#pragma mark -- Delete

/**
 Attempt to delete table without name.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testDeleteTableWithoutTable;

/**
 Attempt to delete table with invalid table name.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testDeleteTableFailure;

/**
 Delete table successfully.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testDeleteTableSuccess;

#pragma mark - Query

// TODO: Add tests for binding and fetching columns.

#pragma mark -- Fetch

// For both fetch and fetch row.
// TODO: Add test for getting `Unable to fetch row, received code %i`.
// TODO: Add test for method forwarding, fetch:|fetch:withParam: > fetch:withParams.
// TODO: Add tests where an error already occurred, i.e. execution of query is a no go.

#pragma mark --- Result

/**
 Attempt to fetch result with bad SQL syntax.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchWithBadSyntax;

/**
 Attempt to fetch result.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchResult;

/**
 Attempt to fetch result, none was found.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchNoResult;

#pragma mark --- Row

/**
 Attempt to fetch row with bad SQL syntax.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchRowWithBadSyntax;

/**
 Attempt to fetch row.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchRow;

/**
 Attempt to fetch row, none was found.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchRowNoResult;

#pragma mark -- Execute

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

	// Have to execute the `check`-method within the execute queue, otherwise
	// `XCTAssertThrows` won't be able to catch the exception.
	[rasqlite queueWithBlock:^(RASqlite *db) {
		XCTAssertThrows([db check], @"Check without structure, no exception thrown.");
	}];
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
				   @"Check with non-existing table was successful.");
}

#pragma mark -- Create

- (void)testCreateWithoutStructure
{
	NSString *path = [_directory stringByAppendingString:@"/create"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	// Have to execute the `create`-method within the execute queue, otherwise
	// `XCTAssertThrows` won't be able to catch the exception.
	[rasqlite queueWithBlock:^(RASqlite *db) {
		XCTAssertThrows([db create], @"Create without structure, no exception thrown.");
	}];
}

- (void)testCreateTableWithoutTable
{
	NSString *path = [_directory stringByAppendingString:@"/create"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSDictionary *columns = @{@"id": RASqliteInteger};
	XCTAssertThrows([rasqlite createTable:nil withColumns:columns],
					@"Create without table name did not throw exception.");
}

- (void)testCreateTableWithoutColumns
{
	NSString *path = [_directory stringByAppendingString:@"/create"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	XCTAssertThrows([rasqlite createTable:@"foo" withColumns:nil],
					@"Create without columns did not throw exception.");
}

- (void)testCreateTable
{
	NSString *path = [_directory stringByAppendingString:@"/create"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSMutableDictionary *columns = [[NSMutableDictionary alloc] init];
	[columns setObject:RASqliteInteger forKey:@"int"];
	[columns setObject:RASqliteText forKey:@"text"];
	[columns setObject:RASqliteReal forKey:@"real"];
	[columns setObject:RASqliteBlob forKey:@"blob"];

	XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
				   @"Create table was not successful: %@", [[rasqlite error] localizedDescription]);
}

- (void)testCreateTableWithNullType
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	[rasqlite queueWithBlock:^(RASqlite *db) {
		NSDictionary *columns = @{@"null": RASqliteNull};
		XCTAssertThrows([rasqlite createTable:@"foo" withColumns:columns],
						@"Created table with `RASqliteNull` data type.");
	}];
}

#pragma mark -- Delete

- (void)testDeleteTableWithoutTable
{
	NSString *path = [_directory stringByAppendingString:@"/delete"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	XCTAssertThrows([rasqlite deleteTable:nil],
					@"Delete without table name did not throw exception.");
}

- (void)testDeleteTableFailure
{
	NSString *path = [_directory stringByAppendingString:@"/delete"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	XCTAssertFalse([rasqlite deleteTable:@"1foo"],
				   @"Delete table with invalid name was successful.");
}

- (void)testDeleteTableSuccess
{
	NSString *path = [_directory stringByAppendingString:@"/delete"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	XCTAssertTrue([rasqlite deleteTable:@"foo"],
				  @"Delete table failed.");
}

#pragma mark - Query

#pragma mark -- Fetch

#pragma mark --- Result

- (void)testFetchWithBadSyntax
{
	NSString *path = [_directory stringByAppendingString:@"/fetch"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	XCTAssertNil([rasqlite fetch:@"foo"], @"Fetched result with bad SQL syntax.");
	XCTAssertNotNil([rasqlite error], @"Error is `nil` with bad SQL syntax.");
}

- (void)testFetchResult
{
	NSString *path = [_directory stringByAppendingString:@"/fetch"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	id result = [rasqlite fetch:@"SELECT 1 AS `id`"];
	XCTAssertTrue([result isKindOfClass:[NSArray class]], @"Result is not type of `NSArray`.");
	XCTAssertNotNil(result, @"Fetch result did not retrieve any results: %@",
					[[rasqlite error] localizedDescription]);
}

- (void)testFetchNoResult
{
	NSString *path = [_directory stringByAppendingString:@"/fetch"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSDictionary *columns = @{@"id": RASqliteInteger};
	XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
				  @"Unable to create table for fetch no result: %@",
				  [[rasqlite error] localizedDescription]);

	id result = [rasqlite fetch:@"SELECT id FROM foo WHERE id = ?" withParam:@1];
	XCTAssertNotNil(result, @"Fetch non-existing row did return `nil` value.");
	XCTAssertTrue([result isKindOfClass:[NSArray class]], @"Result is not type of `NSArray`.");
	XCTAssertTrue([result count] == 0, @"Fetch non-existing row did not return zero rows.");
	XCTAssertNil([rasqlite error], @"Fetch non-existing row triggered an error.");
}

#pragma mark --- Row

- (void)testFetchRowWithBadSyntax
{
	NSString *path = [_directory stringByAppendingString:@"/fetchrow"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	XCTAssertNil([rasqlite fetchRow:@"foo"], @"Fetched row with bad SQL syntax.");
	XCTAssertNotNil([rasqlite error], @"Error is `nil` with bad SQL syntax.");
}

- (void)testFetchRow
{
	NSString *path = [_directory stringByAppendingString:@"/fetch"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	id result = [rasqlite fetchRow:@"SELECT 1 AS `id`"];
	XCTAssertTrue([result isKindOfClass:[NSDictionary class]], @"Result is not type of `NSDictionary`.");
	XCTAssertNotNil(result, @"Fetch result did not retrieve any results: %@",
					[[rasqlite error] localizedDescription]);
}

- (void)testFetchRowNoResult
{
	NSString *path = [_directory stringByAppendingString:@"/fetch"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSDictionary *columns = @{@"id": RASqliteInteger};
	XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
				  @"Unable to create table for fetch no result: %@",
				  [[rasqlite error] localizedDescription]);

	id result = [rasqlite fetchRow:@"SELECT id FROM foo WHERE id = ?" withParam:@1];
	XCTAssertNil(result, @"Fetch non-existing row did return `nil` value.");
	XCTAssertNil([rasqlite error], @"Fetch non-existing row triggered an error.");
}

#pragma mark -- Execute

@end