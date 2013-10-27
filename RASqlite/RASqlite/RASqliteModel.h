//
//  RASqliteModel.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface RASqliteModel : NSObject {
@protected dispatch_queue_t _queue;
}

@property (nonatomic, readonly, copy) NSDictionary *structure;

#pragma mark - Initialization

- (id)initWithName:(NSString *)name;

#pragma mark - Database

- (sqlite3 *)database;

- (BOOL)openWithFlags:(int)flags;

- (BOOL)open;

- (BOOL)close;

@end