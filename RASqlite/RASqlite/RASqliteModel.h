//
//  RASqliteModel.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "RASqlite.h"
#import "RASqliteError.h"

@interface RASqliteModel : NSObject {
@protected dispatch_queue_t _queue;
}

/**
 Stores the first occurred error, `nil` if none has occurred.
 */
@property (nonatomic, readwrite, strong) RASqliteError *error;

@property (nonatomic, readonly, copy) NSDictionary *structure;

#pragma mark - Initialization

- (id)initWithName:(NSString *)name;

#pragma mark - Database

- (sqlite3 *)database;

- (NSString *)path;

- (RASqliteError *)openWithFlags:(int)flags;

- (RASqliteError *)open;

- (RASqliteError *)close;

#pragma mark - Query

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params;

- (NSArray *)fetch:(NSString *)sql withParam:(id)param;

- (NSArray *)fetch:(NSString *)sql;

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params;

- (NSDictionary *)fetchRow:(NSString *)sql withParam:(id)param;

- (NSDictionary *)fetchRow:(NSString *)sql;

- (RASqliteError *)execute:(NSString *)sql withParams:(NSArray *)params;

- (RASqliteError *)execute:(NSString *)sql withParam:(id)param;

- (RASqliteError *)execute:(NSString *)sql;

#pragma mark - Transaction

// TODO: Implement support for handling transactions.

@end