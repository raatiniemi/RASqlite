//
//  RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

// Available SQLite data types.
#define kRASqliteNull		@"NULL"
#define kRASqliteInteger	@"INTEGER"
#define kRASqliteReal		@"REAL"
#define kRASqliteText		@"TEXT"
#define kRASqliteBlob		@"BLOB"

// Debug is always enabled unless otherwise instructed by the application.
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

typedef enum {
	RASqliteTransactionDeferred,
	RASqliteTransactionImmediate,
	RASqliteTransactionExclusive,
} RASqliteTransaction;

@interface RASqlite : NSObject {
@protected
	NSString *_name;

	sqlite3 *_database;

	NSError *_error;
}

@property (nonatomic, readonly, strong) NSString *name;

@property (nonatomic, readwrite) sqlite3 *database;

@property (nonatomic, readonly, strong) NSDictionary *structure;

@property (nonatomic, readwrite, strong) NSError *error;

- (id)initWithName:(NSString *)name;

- (NSError *)open;

- (NSError *)close;

- (NSError *)create;

- (NSError *)createTable:(NSString *)table withColumns:(NSDictionary *)columns;

- (NSError *)deleteTable:(NSString *)table;

- (NSError *)check;

- (NSError *)checkTable:(NSString *)table withColumns:(NSDictionary *)columns;

- (NSArray *)fetch:(NSString *)sql;

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params;

- (NSDictionary *)fetchRow:(NSString *)sql;

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params;

- (NSError *)execute:(NSString *)sql;

- (NSError *)execute:(NSString *)sql withParams:(NSArray *)params;

- (NSError *)errorWithDescription:(NSString *)description code:(NSInteger)code;

- (NSError *)beginTransaction:(RASqliteTransaction)type;

- (NSError *)beginTransaction;

- (NSError *)rollBack;

- (NSError *)commit;

- (NSNumber *)lastInsertId;

@end