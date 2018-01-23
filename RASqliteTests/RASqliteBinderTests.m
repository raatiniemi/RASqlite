//
//  RASqliteBinderTests.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-14.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RASqlite.h"
#import "RASqlite+RASqliteTable.h"

static NSString * const _databasePath = @"/tmp/rasqlite/binder";

@interface RASqliteBinderTests : XCTestCase {
@private
    RASqlite *_rasqlite;
}

@end

@implementation RASqliteBinderTests

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
    [_rasqlite createTable:@"table_name"
               withColumns:@[
                       [self buildColumnWithName:@"text" andType:RASqliteText],
                       [self buildColumnWithName:@"integer" andType:RASqliteInteger],
                       [self buildColumnWithName:@"real" andType:RASqliteReal],
                       [self buildColumnWithName:@"blob" andType:RASqliteBlob]
               ]];
}

- (void)tearDown {
    [NSFileManager.defaultManager removeItemAtPath:_databasePath error:nil];

    [super tearDown];
}

#pragma mark - Test

#pragma mark -- Null

- (void)testBindNull {
    [_rasqlite execute:@"INSERT INTO table_name (text) VALUES (?)" withParam:[NSNull null]];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT text FROM table_name LIMIT 1"];

    XCTAssertEqualObjects([NSNull null], row[@"text"]);
}

#pragma mark -- Text

- (void)testBindText {
    NSString *value = @"value";

    [_rasqlite execute:@"INSERT INTO table_name (text) VALUES (?)" withParam:value];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT text FROM table_name LIMIT 1"];

    XCTAssertEqualObjects(value, row[@"text"]);
}

#pragma mark -- Integer

- (void)testBindInteger_withInt {
    int value = 1;

    [_rasqlite execute:@"INSERT INTO table_name (integer) VALUES (?)" withParam:@(value)];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT integer FROM table_name LIMIT 1"];

    XCTAssertEqualObjects(@(value), row[@"integer"]);
}

- (void)testBindInteger_withLong {
    long value = 2;

    [_rasqlite execute:@"INSERT INTO table_name (integer) VALUES (?)" withParam:@(value)];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT integer FROM table_name LIMIT 1"];

    XCTAssertEqualObjects(@(value), row[@"integer"]);
}

- (void)testBindInteger_withLongLong {
    long long value = 3;

    [_rasqlite execute:@"INSERT INTO table_name (integer) VALUES (?)" withParam:@(value)];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT integer FROM table_name LIMIT 1"];

    XCTAssertEqualObjects(@(value), row[@"integer"]);
}

#pragma mark -- Real

- (void)testBindReal_withFloat {
    float value = 4.1;

    [_rasqlite execute:@"INSERT INTO table_name (real) VALUES (?)" withParam:@(value)];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT real FROM table_name LIMIT 1"];

    XCTAssertEqualObjects(@(value), row[@"real"]);
}

- (void)testBindReal_withDouble {
    double value = 5.1;

    [_rasqlite execute:RASqliteSF(@"INSERT INTO table_name (real) VALUES (?)") withParam:@(value)];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT real FROM table_name LIMIT 1"];

    XCTAssertEqualObjects(@(value), row[@"real"]);
}

#pragma mark - Blob

- (void)testBindBlob_withDictionary {
    NSDictionary *value = @{@"key": @"value"};
    NSData *packedValue = [NSKeyedArchiver archivedDataWithRootObject:value];

    [_rasqlite execute:@"INSERT INTO table_name (blob) VALUES (?)" withParam:packedValue];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT blob FROM table_name LIMIT 1"];

    XCTAssertEqualObjects(value, [NSKeyedUnarchiver unarchiveObjectWithData:row[@"blob"]]);
}

- (void)testBindBlob_withArray {
    NSArray *value = @[@"value"];
    NSData *packedValue = [NSKeyedArchiver archivedDataWithRootObject:value];

    [_rasqlite execute:@"INSERT INTO table_name (blob) VALUES (?)" withParam:packedValue];
    NSDictionary *row = [_rasqlite fetchRow:@"SELECT blob FROM table_name LIMIT 1"];

    XCTAssertEqualObjects(value, [NSKeyedUnarchiver unarchiveObjectWithData:row[@"blob"]]);
}

@end
