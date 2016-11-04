//
//  RASqlite+RATableTests.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-05-24.
//  Copyright (c) 2014-2016 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RASqlite+RASqliteTable.h"

/// Base directory for the unit test databases.
static NSString *_directory = @"/tmp/rasqlite";

/**
 Unit test for the RASqlite+RATable category.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqlite_RASqliteTableTests : XCTestCase

#pragma mark - Check

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

/**
 Attempt to check table with different number of columns.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckNumberOfColumns;

/**
 Attempt to check table with different order on the columns.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckOrderOfColumns;

// TODO: Add test for default value.

/**
 Attempt to check table structure with primary key miss match.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckWithPrimaryKeyMissmatch;

/**
 Attempt to check table structure with nullable missmatch.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckWithNullableMissmatch;

/**
 Attempt to check table structure with unique key missmatch.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckWithUniqueKeyMissmatch;

#pragma mark - Create

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

#pragma mark - Delete

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

@end

@implementation RASqlite_RASqliteTableTests

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

#pragma mark - Check

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

	NSArray *columns = @[[[RASqliteColumn alloc] initWithName:@"id" type:RASqliteInteger]];
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

	NSArray *columns = @[[[RASqliteColumn alloc] initWithName:@"id" type:RASqliteInteger]];
	XCTAssertFalse([rasqlite checkTable:@"foo" withColumns:columns],
				   @"Check with non-existing table was successful.");
}

- (void)testCheckNumberOfColumns
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSMutableArray *columns = [[NSMutableArray alloc] init];
	RASqliteColumn *column;

	column = [[RASqliteColumn alloc] initWithName:@"foo" type:RASqliteInteger];
	[columns addObject:column];

	// Create the table with the first structure.
	XCTAssertTrue([rasqlite createTable:@"baz" withColumns:columns],
				  @"Unable to create table for number of columns missmatch.");

	column = [[RASqliteColumn alloc] initWithName:@"bar" type:RASqliteInteger];
	[columns addObject:column];

	// Check if the `checkTable:withColumns:` notice the change.
	XCTAssertFalse([rasqlite checkTable:@"baz" withColumns:columns],
				   @"Check with number of columns missmatch failed.");
}

- (void)testCheckOrderOfColumns
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSArray *columns;
	columns = @[[[RASqliteColumn alloc] initWithName:@"foo" type:RASqliteInteger]];

	// Create the table with the first structure.
	XCTAssertTrue([rasqlite createTable:@"baz" withColumns:columns],
				  @"Unable to create table for order of columns missmatch.");

	columns = @[[[RASqliteColumn alloc] initWithName:@"bar" type:RASqliteInteger]];

	// Check if the `checkTable:withColumns:` notice the change.
	XCTAssertFalse([rasqlite checkTable:@"baz" withColumns:columns],
				   @"Check with order of columns missmatch failed.");
}

- (void)testCheckWithPrimaryKeyMissmatch
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSMutableArray *columns = [[NSMutableArray alloc] init];
	RASqliteColumn *column;

	column = [[RASqliteColumn alloc] initWithName:@"foo" type:RASqliteInteger];
	[column setPrimaryKey:YES];
	[columns addObject:column];

	column = [[RASqliteColumn alloc] initWithName:@"bar" type:RASqliteInteger];
	[column setPrimaryKey:NO];
	[columns addObject:column];

	// Create the table with the first structure.
	XCTAssertTrue([rasqlite createTable:@"baz" withColumns:columns],
				  @"Unable to create table for checking primary key missmatch.");

	// Modify the primary key order.
	[[columns objectAtIndex:0] setPrimaryKey:NO];
	[[columns objectAtIndex:1] setPrimaryKey:YES];

	// Check if the `checkTable:withColumns:` notice the change.
	XCTAssertFalse([rasqlite checkTable:@"baz" withColumns:columns],
				   @"Check with primary key missmatch failed.");
}

- (void)testCheckWithNullableMissmatch
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	NSMutableArray *columns = [[NSMutableArray alloc] init];
	RASqliteColumn *column;

	column = [[RASqliteColumn alloc] initWithName:@"foo" type:RASqliteInteger];
	[column setNullable:YES];
	[columns addObject:column];

	// Create the table with the first structure.
	XCTAssertTrue([rasqlite createTable:@"baz" withColumns:columns],
				  @"Unable to create table for checking nullable missmatch.");

	// Modify the nullable structure.
	[[columns objectAtIndex:0] setNullable:NO];

	// Check if the `checkTable:withColumns:` notice the change.
	XCTAssertFalse([rasqlite checkTable:@"baz" withColumns:columns],
				   @"Check with nullable missmatch failed.");
}

- (void)testCheckWithUniqueKeyMissmatch
{
#warning Implement test for unique key missmatch.
}

#pragma mark - Create

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

	NSArray *columns = @[[[RASqliteColumn alloc] initWithName:@"id" type:RASqliteInteger]];
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

	NSMutableArray *columns = [[NSMutableArray alloc] init];
	[columns addObject:[[RASqliteColumn alloc] initWithName:@"int" type:RASqliteInteger]];
	[columns addObject:[[RASqliteColumn alloc] initWithName:@"text" type:RASqliteText]];
	[columns addObject:[[RASqliteColumn alloc] initWithName:@"real" type:RASqliteReal]];
	[columns addObject:[[RASqliteColumn alloc] initWithName:@"blob" type:RASqliteBlob]];

	XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
				  @"Create table was not successful: %@", [[rasqlite error] localizedDescription]);
}

- (void)testCreateTableWithNullType
{
	NSString *path = [_directory stringByAppendingString:@"/check"];
	RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

	[rasqlite queueWithBlock:^(RASqlite *db) {
		// TODO: The RASqliteColumn will throw an exception for `NULL`.
		/*		NSArray *columns = @[[[RASqliteColumn alloc] initWithName:@"null" type:RASqliteNull]];
		 XCTAssertThrows([rasqlite createTable:@"foo" withColumns:columns],
		 @"Created table with `RASqliteNull` data type.");*/
	}];
}

#pragma mark - Delete

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


@end
