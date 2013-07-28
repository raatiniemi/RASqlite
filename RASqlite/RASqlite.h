//
//  RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@interface RASqlite : NSObject {
@protected
	sqlite3 *_database;

	NSError *_error;
}

@property (nonatomic, readwrite) sqlite3 *database;

@property (nonatomic, readwrite, strong) NSError *error;

- (id)initWithName:(NSString *)name;

- (NSArray *)fetch:(NSString *)sql;

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params;

- (NSDictionary *)fetchRow:(NSString *)sql;

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params;

- (void)execute:(NSString *)sql;

- (void)execute:(NSString *)sql withParams:(NSArray *)params;

@end