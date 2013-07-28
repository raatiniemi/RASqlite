//
//  RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

#define kRASqliteNull		@"NULL"
#define kRASqliteInteger	@"INTEGER"
#define kRASqliteReal		@"REAL"
#define kRASqliteText		@"TEXT"
#define kRASqliteBlob		@"BLOB"

// Debug is always enabled unless otherwise instructed by application.
#ifndef kRASqliteDebugEnabled
#define kRASqliteDebugEnabled 1
#endif

#if kRASqliteDebugEnabled
#define RASqliteLog(format, ...)\
	NSLog(\
		(@"<%@:(%d)> " format),\
		[[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
		__LINE__,\
		##__VA_ARGS__\
	);
#else
#define RASqliteLog(...)
#endif

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

- (void)deleteTable:(NSString *)table;

- (void)check;

- (void)checkTable:(NSString *)table withColumns:(NSDictionary *)columns;

- (NSArray *)fetch:(NSString *)sql;

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params;

- (NSDictionary *)fetchRow:(NSString *)sql;

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params;

- (void)execute:(NSString *)sql;

- (void)execute:(NSString *)sql withParams:(NSArray *)params;

@end