//
//  RASqliteTests.m
//  RASqliteTests
//
//  Created by Tobias Raatiniemi on 2013-11-30.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RASqlite+RASqliteTable.h"

/// Base directory for the unit test databases.
static NSString *_directory = @"/tmp/rasqlite";

/**
 Unit test for the core functionality of RASqlite.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqliteTests : XCTestCase

#pragma mark - Initialization

/**
 Test the initialization with `init`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testInit_notSupported;

/**
 Test the initialization with `nil` path.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testInitWihPath_withNilPath;

/**
 Initialization successful test with `initWithPath:`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testInitWithPath_withSuccess;

/**
 Initialization failure test with `initWithPath:`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testInitWithPath_withReadonlyDirectory;

/**
 Initialization successful test with `initWithName:`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 Since the `initWithName:` will just call the designated initializer, i.e.
 `initWithPath:`, there's no need to test the failure.
 */
- (void)testInitWithName_withSuccess;

#pragma mark - Database

/**
 Open database with non-existing database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 Normally when the file do not exists, the file will be created but to test the
 functionality the `SQLITE_OPEN_CREATE` flag have been omitted.
 */
- (void)testOpenWithFlags_withoutExistingFile;

/**
 Open database with existing database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testOpenWithFlags_withExistingFile;

/**
 Open database, create database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testOpenWithFlags_createDatabaseFile;

/**
 Attempt to open database with already open database.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testOpen_withAlreadyOpenDatabase;

#pragma mark -- Close

/**
 Attempt to close non-initialized database.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testClose_withoutInitializedDatabase;

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
- (void)testFetch_withInvalidSyntax;

/**
 Attempt to fetch result.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetch_withResult;

/**
 Attempt to fetch result, none was found.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchWithParam_withoutResult;

#pragma mark --- Row

/**
 Attempt to fetch row with bad SQL syntax.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchRow_withInvalidSyntax;

/**
 Attempt to fetch row.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchRow_withRow;

/**
 Attempt to fetch row, none was found.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testFetchRowWithParam_withoutRow;

#pragma mark -- Execute

/**
 Execute with bad SQL syntax.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testExecute_withInvalidSyntax;

/**
 Attempt to execute insert.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testExecute_withInsert;

/**
 Attempt to execute update.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testExecute_withUpdate;

/**
 Attempt to execute delete.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testExecute_withDelete;

#pragma mark - Transaction

/**
 Commit transaction with insert query.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testQueueTransactionWithBlock_commitInsert;

/**
 Rollback transaction with insert query.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testQueueTransactionWithBlock_rollbackInsert;

/**
 Commit transaction with delete query.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testQueueTransactionWithBlock_commitDelete;

/**
 Rollback transaction with delete query.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)testQueueTransactionWithBlock_rollbackDelete;

/**
 Execute transaction while database is closed.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 There have been issues with the `inTransaction`-method due to non-initialized
 database, since it would attempt to insert `nil` as the `sqlite3`-pointer.
 */
- (void)testQueueTransactionWithBlock_withClosedDatabase;

@end

@implementation RASqliteTests

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

#pragma mark - Initialization

- (void)testInit_notSupported {
    XCTAssertThrows([[RASqlite alloc] init], @"`init` method did not fail.");
}

- (void)testInitWihPath_withNilPath {
    XCTAssertThrows([[RASqlite alloc] initWithPath:nil],
            @"`initWithPath:` did not fail with `nil` as path.");
}

- (void)testInitWithPath_withSuccess {
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:@"/tmp/db"];
    XCTAssertNotNil(rasqlite, @"Database initialization failed with directory `/tmp`.");
}

- (void)testInitWithPath_withReadonlyDirectory {
    // Database initialization should not be successful with readonly directories
    // since the `checkPath:` method checks permissions, among other things.
    XCTAssertThrows([[RASqlite alloc] initWithPath:@"/db"],
            @"Database initialization was successful with the readonly directory `/`.");
}

- (void)testInitWithPath_createNewDirectoryInReadonlyDirectory {
    XCTAssertThrows([[RASqlite alloc] initWithPath:@"/new-directory/db"],
            @"Database initialization was successful with new directory in readonly directory.");
}

- (void)testInitWithPath_withNestedFilePath {
    NSString *path = [_directory stringByAppendingString:@"/existing_file"];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createFileAtPath:path contents:nil attributes:nil];
    NSString *nestedFilePath = [path stringByAppendingString:@"/recursive_file"];

    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:nestedFilePath];

    XCTAssertNotNil(rasqlite, @"Nested file path failed.");
}

- (void)testInitWithPath_withoutExistingDirectory {
    NSString *path = [_directory stringByAppendingString:@"/none_existing_directory/file"];

    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertNotNil(rasqlite, @"Nested file path failed.");
}

- (void)testInitWithName_withSuccess {
    RASqlite *rasqlite = [[RASqlite alloc] initWithName:@"db"];
    XCTAssertNotNil(rasqlite, @"Database initialization failed with name `db`.");
}

#pragma mark - Database

#pragma mark -- Open

- (void)testOpenWithFlags_withoutExistingFile {
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:@"/tmp/none_existing_file"];
    XCTAssertFalse([rasqlite openWithFlags:SQLITE_OPEN_READWRITE],
            @"Open database was successful with non existing file.");
}

- (void)testOpenWithFlags_withExistingFile {
    NSString *path = [_directory stringByAppendingString:@"/existing_file"];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createFileAtPath:path contents:nil attributes:nil];

    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];
    XCTAssertTrue([rasqlite openWithFlags:SQLITE_OPEN_READWRITE],
            @"Open database was failed with existing file: %@", [[rasqlite error] localizedDescription]);
}

- (void)testOpenWithFlags_createDatabaseFile {
    NSString *path = [_directory stringByAppendingString:@"/create_file"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];
    XCTAssertTrue([rasqlite openWithFlags:SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE],
            @"Open database with create failed: %@", [[rasqlite error] localizedDescription]);
}

- (void)testOpen_withAlreadyOpenDatabase {
    NSString *path = [_directory stringByAppendingString:@"/open_database"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];
    XCTAssertTrue([rasqlite open], @"Open database failed: %@", [[rasqlite error] localizedDescription]);
    XCTAssertTrue([rasqlite open], @"Open already open database failed: %@", [[rasqlite error] localizedDescription]);
}

#pragma mark -- Close

- (void)testClose_withoutInitializedDatabase {
    NSString *path = [_directory stringByAppendingString:@"/closed_database"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];
    XCTAssertTrue([rasqlite close],
            @"Close non initialized database failed: %@", [[rasqlite error] localizedDescription]);
}

#pragma mark - Query

#pragma mark -- Fetch

#pragma mark --- Result

- (void)testFetch_withInvalidSyntax {
    NSString *path = [_directory stringByAppendingString:@"/fetch"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertNil([rasqlite fetch:@"foo"], @"Fetched result with bad SQL syntax.");
    XCTAssertNotNil([rasqlite error], @"Error is `nil` with bad SQL syntax.");
}

- (void)testFetch_withResult {
    NSString *path = [_directory stringByAppendingString:@"/fetch"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    id result = [rasqlite fetch:@"SELECT 1 AS `id`"];
    XCTAssertTrue([result isKindOfClass:[NSArray class]], @"Result is not type of `NSArray`.");
    XCTAssertNotNil(result, @"Fetch result did not retrieve any results: %@",
            [[rasqlite error] localizedDescription]);
}

- (void)testFetchWithParam_withoutResult {
    NSString *path = [_directory stringByAppendingString:@"/fetch"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSArray *columns = @[RAColumn(@"id", RASqliteInteger)];
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

- (void)testFetchRow_withInvalidSyntax {
    NSString *path = [_directory stringByAppendingString:@"/fetch-row"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertNil([rasqlite fetchRow:@"foo"], @"Fetched row with bad SQL syntax.");
    XCTAssertNotNil([rasqlite error], @"Error is `nil` with bad SQL syntax.");
}

- (void)testFetchRow_withRow {
    NSString *path = [_directory stringByAppendingString:@"/fetch"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    id row = [rasqlite fetchRow:@"SELECT 1 AS `id`"];
    XCTAssertTrue([row isKindOfClass:[NSDictionary class]], @"Result is not type of `NSDictionary`.");
    XCTAssertNotNil(row, @"Fetch result did not retrieve any results: %@",
            [[rasqlite error] localizedDescription]);
}

- (void)testFetchRowWithParam_withoutRow {
    NSString *path = [_directory stringByAppendingString:@"/fetch"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSArray *columns = @[RAColumn(@"id", RASqliteInteger)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for fetch no result: %@",
            [[rasqlite error] localizedDescription]);

    id row = [rasqlite fetchRow:@"SELECT id FROM foo WHERE id = ?" withParam:@1];
    XCTAssertNil(row, @"Fetch non-existing row did return `nil` value.");
    XCTAssertNil([rasqlite error], @"Fetch non-existing row triggered an error.");
}

#pragma mark -- Execute

- (void)testExecute_withInvalidSyntax {
    NSString *path = [_directory stringByAppendingString:@"/execute"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    XCTAssertFalse([rasqlite execute:@"foo"], @"Executed with bad SQL syntax.");
    XCTAssertNotNil([rasqlite error], @"Error is `nil` with bad SQL syntax.");
}

- (void)testExecute_withInsert {
    NSString *path = [_directory stringByAppendingString:@"/execute"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"id", RASqliteInteger)];
    [columns addObject:RAColumn(@"bar", RASqliteText)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for execute: %@",
            [[rasqlite error] localizedDescription]);

    BOOL insert = [rasqlite execute:@"INSERT INTO foo(id, bar) VALUES(1, ?)" withParam:@"baz"];
    XCTAssertTrue(insert, @"Insert failed: %@", [[rasqlite error] localizedDescription]);

    NSDictionary *row = [rasqlite fetchRow:@"SELECT bar FROM foo WHERE id = ?" withParam:@1];
    XCTAssertEqualObjects(@"baz", row[@"bar"], @"Value for retrieved row do not match.");
}

- (void)testExecute_withUpdate {
    NSString *path = [_directory stringByAppendingString:@"/execute"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"id", RASqliteInteger)];
    [columns addObject:RAColumn(@"bar", RASqliteText)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for execute: %@",
            [[rasqlite error] localizedDescription]);

    BOOL insert = [rasqlite execute:@"INSERT INTO foo(id, bar) VALUES(1, ?)" withParam:@"baz"];
    XCTAssertTrue(insert, @"Insert failed: %@", [[rasqlite error] localizedDescription]);

    BOOL update = [rasqlite execute:@"UPDATE foo SET bar = ? WHERE id = ?" withParams:@[@"quux", @1]];
    XCTAssertTrue(update, @"Update failed: %@", [[rasqlite error] localizedDescription]);

    NSDictionary *row = [rasqlite fetchRow:@"SELECT bar FROM foo WHERE id = ?" withParam:@1];
    XCTAssertEqualObjects(@"quux", row[@"bar"], @"Value for retrieved row do not match.");
}

- (void)testExecute_withDelete {
    NSString *path = [_directory stringByAppendingString:@"/execute"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"id", RASqliteInteger)];
    [columns addObject:RAColumn(@"bar", RASqliteText)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for execute: %@",
            [[rasqlite error] localizedDescription]);

    BOOL insert = [rasqlite execute:@"INSERT INTO foo(id, bar) VALUES(1, ?)" withParam:@"baz"];
    XCTAssertTrue(insert, @"Insert failed: %@", [[rasqlite error] localizedDescription]);

    NSDictionary *row = [rasqlite fetchRow:@"SELECT bar FROM foo WHERE id = ?" withParam:@1];
    XCTAssertNotNil(row, @"Inserted row was not found.");

    BOOL update = [rasqlite execute:@"DELETE FROM foo WHERE id = ?" withParam:@1];
    XCTAssertTrue(update, @"Delete failed: %@", [[rasqlite error] localizedDescription]);

    row = [rasqlite fetchRow:@"SELECT bar FROM foo WHERE id = ?" withParam:@1];
    XCTAssertNil(row, @"Deleted row was found.");
}

#pragma mark - Transaction

- (void)testQueueTransactionWithBlock_commitInsert {
    NSString *path = [_directory stringByAppendingString:@"/transaction"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"id", RASqliteInteger)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for `%s`: %@",
            __PRETTY_FUNCTION__,
            [[rasqlite error] localizedDescription]);

    [rasqlite queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
        *commit = [db execute:@"INSERT INTO foo(id) VALUES(1)"];
        XCTAssertTrue(*commit, @"Unable to insert for `%s`: %@",
                __PRETTY_FUNCTION__,
                [[db error] localizedDescription]);
    }];

    XCTAssertNotNil([rasqlite fetchRow:@"SELECT id FROM foo WHERE id = 1"],
            @"Commit transaction with insert did not insert row.");
}

- (void)testQueueTransactionWithBlock_rollbackInsert {
    NSString *path = [_directory stringByAppendingString:@"/transaction"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"id", RASqliteInteger)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for `%s`: %@",
            __PRETTY_FUNCTION__,
            [[rasqlite error] localizedDescription]);

    [rasqlite queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
        *commit = [db execute:@"INSERT INTO foo(id) VALUES(1)"];
        XCTAssertTrue(*commit, @"Unable to insert for `%s`: %@",
                __PRETTY_FUNCTION__,
                [[db error] localizedDescription]);

        // We have to force a rollback.
        *commit = NO;
    }];

    XCTAssertNil([rasqlite fetchRow:@"SELECT id FROM foo WHERE id = 1"],
            @"Rollback transaction with insert did insert row.");
}

- (void)testQueueTransactionWithBlock_commitDelete {
    NSString *path = [_directory stringByAppendingString:@"/transaction"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"id", RASqliteInteger)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for `%s`: %@",
            __PRETTY_FUNCTION__,
            [[rasqlite error] localizedDescription]);

    BOOL insert = [rasqlite execute:@"INSERT INTO foo(id) VALUES(1)"];
    XCTAssertTrue(insert, @"Unable to insert for `%s`: %@",
            __PRETTY_FUNCTION__,
            [[rasqlite error] localizedDescription]);

    XCTAssertNotNil([rasqlite fetchRow:@"SELECT id FROM foo WHERE id = 1"],
            @"Insert did not insert row.");

    [rasqlite queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
        *commit = [rasqlite execute:@"DELETE FROM foo WHERE id = 1"];
        XCTAssertTrue(*commit, @"Unable to delete for `%s`: %@",
                __PRETTY_FUNCTION__,
                [[rasqlite error] localizedDescription]);
    }];

    XCTAssertNil([rasqlite fetchRow:@"SELECT id FROM foo WHERE id = 1"],
            @"Commit transaction with delete did not delete row.");
}

- (void)testQueueTransactionWithBlock_rollbackDelete {
    NSString *path = [_directory stringByAppendingString:@"/transaction"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"id", RASqliteInteger)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for `%s`: %@",
            __PRETTY_FUNCTION__,
            [[rasqlite error] localizedDescription]);

    BOOL insert = [rasqlite execute:@"INSERT INTO foo(id) VALUES(1)"];
    XCTAssertTrue(insert, @"Unable to insert for `%s`: %@",
            __PRETTY_FUNCTION__,
            [[rasqlite error] localizedDescription]);

    XCTAssertNotNil([rasqlite fetchRow:@"SELECT id FROM foo WHERE id = 1"],
            @"Insert did not insert row.");

    [rasqlite queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
        *commit = [rasqlite execute:@"DELETE FROM foo WHERE id = 1"];
        XCTAssertTrue(*commit, @"Unable to delete for `%s`: %@",
                __PRETTY_FUNCTION__,
                [[rasqlite error] localizedDescription]);

        // We have to force a rollback.
        *commit = NO;
    }];

    XCTAssertNotNil([rasqlite fetchRow:@"SELECT id FROM foo WHERE id = 1"],
            @"Rollback transaction with delete did delete row.");
}

- (void)testQueueTransactionWithBlock_withClosedDatabase {
    NSString *path = [_directory stringByAppendingString:@"/transaction"];
    RASqlite *rasqlite = [[RASqlite alloc] initWithPath:path];

    NSMutableArray *columns = [[NSMutableArray alloc] init];
    [columns addObject:RAColumn(@"id", RASqliteInteger)];
    XCTAssertTrue([rasqlite createTable:@"foo" withColumns:columns],
            @"Unable to create table for `%s`: %@",
            __PRETTY_FUNCTION__,
            [[rasqlite error] localizedDescription]);

    // Force close the database instance.
    [rasqlite close];

    [rasqlite queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
        *commit = [db execute:@"INSERT INTO foo(id) VALUES(1)"];
        XCTAssertTrue(*commit, @"Unable to insert for `%s`: %@",
                __PRETTY_FUNCTION__,
                [[db error] localizedDescription]);
    }];

    XCTAssertNotNil([rasqlite fetchRow:@"SELECT id FROM foo WHERE id = 1"],
            @"Commit transaction with insert did not insert row.");
}

@end