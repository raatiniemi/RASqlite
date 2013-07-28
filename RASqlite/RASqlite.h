//
//  RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

#define RASqliteNull	@"NULL"
#define RASqliteInteger	@"INTEGER"
#define RASqliteReal	@"REAL"
#define RASqliteText	@"TEXT"
#define RASqliteBlob	@"BLOB"

@interface RASqlite : NSObject {
@protected
	sqlite3 *_database;

	NSError *_error;
}

@property (nonatomic, readwrite) sqlite3 *database;

@property (nonatomic, readonly, strong) NSDictionary *structure;

@property (nonatomic, readwrite, strong) NSError *error;

- (id)initWithName:(NSString *)name;

- (void)create;

- (void)createTable:(NSString *)table withColumns:(NSDictionary *)columns;

- (void)check;

- (void)checkTable:(NSString *)table withColumns:(NSDictionary *)columns;

- (NSArray *)fetch:(NSString *)sql;

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params;

- (NSDictionary *)fetchRow:(NSString *)sql;

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params;

- (void)execute:(NSString *)sql;

- (void)execute:(NSString *)sql withParams:(NSArray *)params;

@end