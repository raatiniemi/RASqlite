//
//  RATerminalModel.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-04.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import "RATerminalModel.h"

static RATerminalModel *_sharedModel = nil;

@implementation RATerminalModel

#pragma mark - Initialization

- (id)init {
    if (self = [super initWithPath:@"/tmp/rasqlite-user.db"]) {
        [self queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
            // Iterate over the table structure.
            for (NSString *table in [self structure]) {
                NSArray *columns = [self structure][table];

                // Check if the structure for the table have changed.
                if (!(*commit = [db checkTable:table withColumns:columns])) {
                    // The structure have changed, delete the table and
                    // recreate it with the new column structure.
                    *commit = [db deleteTable:table];
                    if (*commit) {
                        *commit = [db createTable:table withColumns:columns];
                    }
                }

                // If either of the operations fails the transaction is failed.
                if (!*commit) {
                    break;
                }
            }
        }];
    }
    return self;
}

+ (RATerminalModel *)sharedModel {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedModel = [[RATerminalModel alloc] init];
    });

    return _sharedModel;
}

#pragma mark - Database

- (NSDictionary *)structure {
    NSMutableArray *user = [[NSMutableArray alloc] init];
    RASqliteColumn *column;

    column = RAColumn(@"id", RASqliteInteger);
    [column setAutoIncrement:YES];
    [column setPrimaryKey:YES];
    [user addObject:column];

    column = RAColumn(@"name", RASqliteText);
    [user addObject:column];

    column = RAColumn(@"email", RASqliteText);
    [column setNullable:YES];
    [user addObject:column];

    column = RAColumn(@"level", RASqliteInteger);
    [column setDefaultValue:@1];
    [user addObject:column];

    NSMutableDictionary *tables = [[NSMutableDictionary alloc] init];
    tables[@"user"] = user;

    return tables;
}

#pragma mark - Handle users

- (NSDictionary *)getUser:(NSString *)name {
    return [self fetchRow:@"SELECT id FROM user WHERE name = ? LIMIT 1" withParam:name];
}

- (NSArray *)getUsers {
    return [self fetch:@"SELECT id, name FROM user"];
}

- (BOOL)addUser:(NSString *)name {
    return [self execute:@"INSERT INTO user(name) VALUES(?)" withParam:name];
}

- (BOOL)removeUser:(NSNumber *)userId {
    return [self execute:@"DELETE FROM user WHERE id = ?" withParam:userId];
}

@end