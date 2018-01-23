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
- (void)testCheck_withoutStructure;

// TODO: Test with structure with mock.

/**
 Attempt to check table without table name.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithColumns_withoutTable;

/**
 Attempt to check table without columns.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithColumns_withoutColumns;

/**
 Attempt to check non-existing table.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithColumns_withoutExistingTable;

/**
 Attempt to check table with different number of columns.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithColumns_withIncorrectNumberOfColumns;

/**
 Attempt to check table with different order on the columns.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithColumns_withIncorrectOrderOfColumns;

// TODO: Add test for default value.

/**
 Attempt to check table structure with primary key mismatch.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithColumns_withPrimaryKeyMismatch;

/**
 Attempt to check table structure with nullable mismatch.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithColumns_withNullableMismatch;

/**
 Attempt to check table structure with unique key mismatch.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCheckTableWithColumns_withUniqueKeyMismatch;

#pragma mark - Create

/**
 Attempt to create table without structure.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreate_withoutStructure;

// TODO: Test with structure with mock.

/**
 Attempt to create table without table name.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateTableWithColumns_withoutTable;

/**
 Attempt to create table without columns.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateTableWithColumns_withoutColumns;

/**
 Attempt to create table with available data types.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateTableWithColumns_withSuccess;

/**
 Attempt to create table with null data type.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testCreateTableWithColumns_withNullType;

#pragma mark - Delete

/**
 Attempt to delete table without name.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testDeleteTable_withoutTable;

/**
 Attempt to delete table with invalid table name.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testDeleteTable_withInvalidTableName;

/**
 Delete table successfully.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testDeleteTable_withSuccess;

@end

@implementation RASqlite_RASqliteTableTests

#pragma mark - Setup/tear down

- (void)setUp {
    [super setUp];

    // Create the directory that will contain the unit test files.
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)tearDown {
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:_directory error:nil];

    [super tearDown];
}

#pragma mark - Check

- (void)testCheck_withoutStructure {
    NSString *path = [_directory stringByAppendingString:@"/check"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    // Have to execute the `check`-method within the execute queue, otherwise
    // `XCTAssertThrows` won't be able to catch the exception.
    [rasqlite queueWithBlock:^(RASqlite *db) {
        XCTAssertThrows([db check], @"Check without structure, no exception thrown.");
    }];
}

- (void)testCheckTableWithColumns_withoutTable {
    NSString *path = [_directory stringByAppendingString:@"/check"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSArray *columns = @[RAColumn(@"id", RASqliteInteger)];
    XCTAssertThrows([rasqlite checkTable:nil withColumns:columns],
            @"Check without table name did not throw exception.");
}

- (void)testCheckTableWithColumns_withoutColumns {
    NSString *path = [_directory stringByAppendingString:@"/check"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertThrows([rasqlite checkTable:@"foo" withColumns:nil],
            @"Check without columns did not throw exception.");
}

- (void)testCheckTableWithColumns_withoutExistingTable {
    NSString *path = [_directory stringByAppendingString:@"/check"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSArray *columns = @[RAColumn(@"id", RASqliteInteger)];
    XCTAssertFalse([rasqlite checkTable:@"foo" withColumns:columns],
            @"Check with non-existing table was successful.");
}

- (void)testCheckTableWithColumns_withIncorrectNumberOfColumns {
    NSString *path = [_directory stringByAppendingString:@"/check"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"foo", RASqliteInteger)];

    // Create the table with the first structure.
    XCTAssertTrue([rasqlite createTable:@"baz" withColumns:columns],
            @"Unable to create table for number of columns mismatch.");

    [columns addObject:RAColumn(@"bar", RASqliteInteger)];

    // Check if the `checkTable:withColumns:` notice the change.
    XCTAssertFalse([rasqlite checkTable:@"baz" withColumns:columns],
            @"Check with number of columns mismatch failed.");
}

- (void)testCheckTableWithColumns_withIncorrectOrderOfColumns {
    NSString *path = [_directory stringByAppendingString:@"/check"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSArray *columns = @[RAColumn(@"foo", RASqliteInteger)];

    // Create the table with the first structure.
    XCTAssertTrue([rasqlite createTable:@"baz" withColumns:columns],
            @"Unable to create table for order of columns mismatch.");

    columns = @[RAColumn(@"bar", RASqliteInteger)];

    // Check if the `checkTable:withColumns:` notice the change.
    XCTAssertFalse([rasqlite checkTable:@"baz" withColumns:columns],
            @"Check with order of columns mismatch failed.");
}

- (void)testCheckTableWithColumns_withPrimaryKeyMismatch {
    NSString *path = [_directory stringByAppendingString:@"/check"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    RASqliteColumn *column;

    column = RAColumn(@"foo", RASqliteInteger);
    [column setPrimaryKey:YES];
    [columns addObject:column];

    column = RAColumn(@"bar", RASqliteInteger);
    [column setPrimaryKey:NO];
    [columns addObject:column];

    // Create the table with the first structure.
    XCTAssertTrue([rasqlite createTable:@"baz" withColumns:columns],
            @"Unable to create table for checking primary key mismatch.");

    // Modify the primary key order.
    [columns[0] setPrimaryKey:NO];
    [columns[1] setPrimaryKey:YES];

    // Check if the `checkTable:withColumns:` notice the change.
    XCTAssertFalse([rasqlite checkTable:@"baz" withColumns:columns],
            @"Check with primary key mismatch failed.");
}

- (void)testCheckTableWithColumns_withNullableMismatch {
    NSString *path = [_directory stringByAppendingString:@"/check"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    RASqliteColumn *column;

    column = RAColumn(@"foo", RASqliteInteger);
    [column setNullable:YES];
    [columns addObject:column];

    // Create the table with the first structure.
    XCTAssertTrue([rasqlite createTable:@"baz" withColumns:columns],
            @"Unable to create table for checking nullable mismatch.");

    // Modify the nullable structure.
    [columns[0] setNullable:NO];

    // Check if the `checkTable:withColumns:` notice the change.
    XCTAssertFalse([rasqlite checkTable:@"baz" withColumns:columns],
            @"Check with nullable mismatch failed.");
}

- (void)testCheckTableWithColumns_withUniqueKeyMismatch {
#warning Implement test for unique key missmatch.
}

#pragma mark - Create

- (void)testCreate_withoutStructure {
    NSString *path = [_directory stringByAppendingString:@"/create"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    // Have to execute the `create`-method within the execute queue, otherwise
    // `XCTAssertThrows` won't be able to catch the exception.
    [rasqlite queueWithBlock:^(RASqlite *db) {
        XCTAssertThrows([db create], @"Create without structure, no exception thrown.");
    }];
}

- (void)testCreateTableWithColumns_withoutTable {
    NSString *path = [_directory stringByAppendingString:@"/create"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSArray *columns = @[RAColumn(@"id", RASqliteInteger)];
    XCTAssertThrows([rasqlite createTable:nil withColumns:columns],
            @"Create without table name did not throw exception.");
}

- (void)testCreateTableWithColumns_withoutColumns {
    NSString *path = [_directory stringByAppendingString:@"/create"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertThrows([rasqlite createTable:@"foo" withColumns:nil],
            @"Create without columns did not throw exception.");
}

- (void)testCreateTableWithColumns_withSuccess {
    NSString *path = [_directory stringByAppendingString:@"/create"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"int", RASqliteInteger)];
    [columns addObject:RAColumn(@"text", RASqliteText)];
    [columns addObject:RAColumn(@"real", RASqliteReal)];
    [columns addObject:RAColumn(@"blob", RASqliteBlob)];

    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Create table was not successful: %@", [[rasqlite error] localizedDescription]);
}

- (void)testCreateTableWithColumns_withNullType {
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

- (void)testDeleteTable_withoutTable {
    NSString *path = [_directory stringByAppendingString:@"/delete"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertThrows([rasqlite deleteTable:nil],
            @"Delete without table name did not throw exception.");
}

- (void)testDeleteTable_withInvalidTableName {
    NSString *path = [_directory stringByAppendingString:@"/delete"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertFalse([rasqlite deleteTable:@"1foo"],
            @"Delete table with invalid name was successful.");
}

- (void)testDeleteTable_withSuccess {
    NSString *path = [_directory stringByAppendingString:@"/delete"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertTrue([rasqlite deleteTable:@"foo"],
            @"Delete table failed.");
}

@end
