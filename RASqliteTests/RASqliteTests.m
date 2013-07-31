//
//  RASqliteTests.m
//  RASqliteTests
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import "RASqliteTests.h"

@implementation RASqliteTests

- (void)setUp
{
	[super setUp];
}

- (void)tearDown
{
	// -- -- Remove created database files.

	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [directories objectAtIndex:0];

	NSError *error;
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
	if ( error == nil ) {
		NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"\\b([A-Z0-9]+\\.db)\\b" options:NSRegularExpressionCaseInsensitive error:&error];
		NSTextCheckingResult *match;
		if ( error == nil ) {
			for ( NSString *file in files ) {
				match = [regexp firstMatchInString:file options:0 range:NSMakeRange(0, [file length])];
				if ( match ) {
					[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingFormat:@"/%@", file] error:&error];
					if ( error != nil ) {
						STFail(@"%@", [error localizedDescription]);
					}
				}
			}
		} else {
			STFail(@"%@", [error localizedDescription]);
		}
	} else {
		STFail(@"%@", [error localizedDescription]);
	}

	[super tearDown];
}

#pragma mark - Init

- (void)testInit
{
	STAssertThrows([[RASqlite alloc] init], @"Expected raised exception, none was thrown.");
}

- (void)testInitWithName
{
	NSString *name = @"testInitWithName.db";
	RASqlite *db = [[RASqlite alloc] initWithName:name];

	STAssertEquals([db name], name, @"Database name `%@` as expected, `%@` was recived", name, [db name]);
}

#pragma mark - Open

- (void)testOpen
{
	RASqlite *db = [[RASqlite alloc] initWithName:@"testOpen.db"];
	NSError *openError = [db open];
	STAssertNil(openError, @"Expected `nil`, recived an `%@` with message `%@`.", [openError class], [openError localizedDescription]);
}

- (void)testOpenFailed
{
	// TODO: Implement failed database open.
}

#pragma mark - Close

- (void)testClose
{
	RASqlite *db = [[RASqlite alloc] initWithName:@"testClose.db"];
	STAssertNil([db close], @"An error has occured during [db close].");
}

- (void)testCloseFailed
{
	// TODO: Implement database close.
}

#pragma mark - Create

- (void)testCreate
{
	// TODO: Setup table creation.
}

- (void)testCreateFailed
{
	RASqlite *db = [[RASqlite alloc] initWithName:@"testCreate.db"];
	NSError *openError = [db open];
	STAssertNil(openError, @"Expected `nil`, recived an `%@` with message `%@`.", [openError class], [openError localizedDescription]);

	NSError *error = [db create];
	STAssertEquals([error class], [NSError class], @"Expected `%@`, recived `%@`.", [NSError class], [error class]);
}

#pragma mark -- Create table

- (void)testCreateTable
{
	RASqlite *db = [[RASqlite alloc] initWithName:@"testCreateTable.db"];
	NSError *openError = [db open];
	STAssertNil(openError, @"Expected `nil`, recived an `%@` with message `%@`.", [openError class], [openError localizedDescription]);

	NSDictionary *columns;
	NSError *error;

	columns = [NSDictionary dictionaryWithObject:kRASqliteNull forKey:@"Field"];
	error = [db createTable:@"Table1" withColumns:columns];
	STAssertNil(error, @"Expected `nil`, recived `%@`", [error class]);

	columns = [NSDictionary dictionaryWithObject:kRASqliteInteger forKey:@"Field"];
	error = [db createTable:@"Table2" withColumns:columns];
	STAssertNil(error, @"Expected `nil`, recived `%@`", [error class]);

	columns = [NSDictionary dictionaryWithObject:kRASqliteReal forKey:@"Field"];
	error = [db createTable:@"Table3" withColumns:columns];
	STAssertNil(error, @"Expected `nil`, recived `%@`", [error class]);

	columns = [NSDictionary dictionaryWithObject:kRASqliteText forKey:@"Field"];
	error = [db createTable:@"Table4" withColumns:columns];
	STAssertNil(error, @"Expected `nil`, recived `%@`", [error class]);

	columns = [NSDictionary dictionaryWithObject:kRASqliteBlob forKey:@"Field"];
	error = [db createTable:@"Table5" withColumns:columns];
	STAssertNil(error, @"Expected `nil`, recived `%@`", [error class]);
}

- (void)testCreateTableFailed
{
	RASqlite *db = [[RASqlite alloc] initWithName:@"testCreateTableFailed.db"];
	NSError *openError = [db open];
	STAssertNil(openError, @"Expected `nil`, recived an `%@` with message `%@`.", [openError class], [openError localizedDescription]);

	NSError *error = [db createTable:nil withColumns:nil];
	STAssertEquals([error class], [NSError class], @"Expected `%@`, recived `%@`.", [NSError class], [error class]);

	error = [db createTable:@"Table" withColumns:nil];
	STAssertEquals([error class], [NSError class], @"Expected `%@`, recived `%@`.", [NSError class], [error class]);

	error = [db createTable:@"Table" withColumns:[NSDictionary dictionaryWithObject:@"Foo" forKey:@"Field"]];
	STAssertEquals([error class], [NSError class], @"Expected `%@`, recived `%@`.", [NSError class], [error class]);
}

#pragma mark - Execute

- (void)testExecute
{
	RASqlite *db = [[RASqlite alloc] initWithName:@"testExecute.db"];
	NSError *openError = [db open];
	STAssertNil(openError, @"Expected `nil`, recived an `%@` with message `%@`.", [openError class], [openError localizedDescription]);
}

@end