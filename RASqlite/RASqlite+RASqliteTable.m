//
//  RASqlite+RASqliteTable.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-05-24.
//  Copyright (c) 2014-2016 Raatiniemi. All rights reserved.
//

#import "RASqlite+RASqliteTable.h"

// -- -- Exception

/// Exception name for issues with checking of database structure.
static NSString *RASqliteCheckDatabaseException = @"Check database";

/// Exception name for issues with checking of table structure.
static NSString *RASqliteCheckTableException = @"Check table";

/// Exception name for issues with table removal.
static NSString *RASqliteRemoveTableException = @"Remove table";

@implementation RASqlite (RASqliteTable)

- (BOOL)check {
    // Keep track if whether the structure for the table is valid.
    //
    // The default value have to be `YES`, otherwise we risk of deleting the
    // table when something is wrong with the database instance.
    BOOL __block valid = YES;

    [self queueWithBlock:^(RASqlite *db) {
        NSDictionary *tables = [db structure];
        if (tables) {
            // Get the pointer for the method, performance improvement.
            SEL selector = @selector(checkTable:withColumns:status:);

            typedef BOOL (*check)(id, SEL, NSString *, NSArray *, RASqliteTableCheckStatus **);
            check checkTable = (check) [db methodForSelector:selector];

            // Checking whether the database instance have implemented
            // methods for before and after table check handling.
            BOOL isBeforeAvailable = [db respondsToSelector:@selector(beforeTableCheck:)];
            BOOL isAfterAvailable = [db respondsToSelector:@selector(afterTableCheck:withStatus:)];

            RASqliteTableCheckStatus *status;
            for (NSString *table in tables) {
                // If the before check method is available and it returns
                // `NO` we should move on to the next table.
                if (isBeforeAvailable && ![db beforeTableCheck:table]) {
                    continue;
                }

                status = (RASqliteTableCheckStatus *) RASqliteTableCheckStatusClean;
                checkTable(db, selector, table, tables[table], &status);

                // If the after check method is available we have to execute it,
                // sending the current status of the table.
                // This way we can determined what to do about the changes (if any).
                if (isAfterAvailable) {
                    [db afterTableCheck:table withStatus:status];
                }
            }
        } else {
            // Raise an exception, no structure have been supplied.
            [NSException raise:RASqliteCheckDatabaseException
                        format:@"Unable to check database structure, none has been supplied."];
        }
    }];

    return valid;
}

- (BOOL)checkTable:(NSString *)table withColumns:(NSArray *)columns {
    if (!table) {
        // Raise an exception, no valid table name.
        [NSException raise:NSInvalidArgumentException
                    format:@"Unable to check table without valid name."];
    }

    if (!columns) {
        // Raise an exception, no defined columns.
        [NSException raise:NSInvalidArgumentException
                    format:@"Unable to check table without defined columns."];
    }

    // Keeps track on whether the structure for the table is valid.
    //
    // The default value have to be `YES`, otherwise we risk of deleting the
    // table when something is wrong with the database instance.
    BOOL __block valid = YES;

    [self queueWithBlock:^(RASqlite *db) {
        // Check whether the defined columns and the table columns match.
        NSArray *tColumns = [db fetch:RASqliteSF(@"PRAGMA table_info(%@)", table)];
        if ([tColumns count] > 0) {
            if ([tColumns count] == [columns count]) {
                unsigned int index = 0;
                for (RASqliteColumn *column in columns) {
                    // The column have to be of type `RASqliteColumn`.
                    if (![column isKindOfClass:[RASqliteColumn class]]) {
                        [NSException raise:NSInvalidArgumentException
                                    format:@"Column defined for table `%@` at index `%i` is not of type `RASqliteColumn.", table, index];
                    }

                    // Retrieve the column definition from the table.
                    NSDictionary *tColumn = tColumns[index];

                    // Check that the column name matches.
                    if (![[tColumn getColumn:@"name"] isEqualToString:[column name]]) {
                        RASqliteDebugLog(@"Column name at index `%i` do not match column given for structure `%@`.", index, table);
                        valid = NO;
                        break;
                    }

                    // Check that the column type matches.
                    if (![[tColumn getColumn:@"type"] isEqualToString:[column type]]) {
                        RASqliteDebugLog(@"Column type at index `%i` do not match column given for structure `%@`.", index, table);
                        valid = NO;
                        break;
                    }

                    // Check that whether the column matches the primary key setting.
                    if ([column isPrimaryKey] != [[tColumn getColumn:@"pk"] boolValue]) {
                        RASqliteDebugLog(@"Column primary key option at index `%i` do not match column given for structure `%@`.", index, table);
                        valid = NO;
                        break;
                    }

                    // Check that whether the column matches the nullable setting.
                    if ([column isNullable] == [[tColumn getColumn:@"notnull"] boolValue]) {
                        RASqliteDebugLog(@"Column nullable option at index `%i` do not match column given for structure `%@`.", index, table);
                        valid = NO;
                        break;
                    }

                    // TODO: Check the default value, `dflt_value` from tColumn.
                    // TODO: Check for unique columns.
                    // TODO: Check for autoincremental.

                    index++;
                }
            } else {
                RASqliteDebugLog(@"Number of specified columns for table `%@` do not matched the defined table count.", table);
                valid = NO;
            }
        } else {
            RASqliteDebugLog(@"Table `%@` do not exist with any structure within the database.", table);
            valid = NO;
        }
    }];

    return valid;
}

- (BOOL)checkTable:(NSString *)table withColumns:(NSArray *)columns status:(RASqliteTableCheckStatus **)status {
    return [self checkTable:table withColumns:columns];
}

- (BOOL)create {
    // Keeps track on whether the structure was created.
    BOOL __block created = NO;

    [self queueWithBlock:^(RASqlite *db) {
        NSDictionary *tables = [self structure];
        if (tables) {
            // Get the pointer for the method, performance improvement.
            SEL selector = @selector(createTable:withColumns:);

            typedef BOOL (*create)(id, SEL, NSString *, NSDictionary *);
            create createTable = (create) [db methodForSelector:selector];

            // Change the created check before going in to the create loop.
            created = YES;

            // Loops through each of the tables and attempt to create their structure.
            for (NSString *table in tables) {
                if (!createTable(db, selector, table, tables[table])) {
                    created = NO;
                    break;
                }
            }
        } else {
            // Raise an exception, no structure have been supplied.
            [NSException raise:RASqliteCheckDatabaseException
                        format:@"Unable to create database structure, none has been supplied."];
        }
    }];

    return created;
}

- (BOOL)createTable:(NSString *)table withColumns:(NSArray *)columns {
    if (!table) {
        // Raise an exception, no valid table name.
        [NSException raise:NSInvalidArgumentException
                    format:@"Unable to create table without valid name."];
    }

    if (!columns) {
        // Raise an exception, no defined columns.
        [NSException raise:NSInvalidArgumentException
                    format:@"Unable to create table without defined columns."];
    }

    // Keeps track on whether the table was created.
    BOOL __block created = NO;

    [self queueWithBlock:^(RASqlite *db) {
        // The create query will be constructed with a list of items, each
        // item represent their column name, data type, constraints, etc.
        NSMutableArray *list = [[NSMutableArray alloc] init];
        NSMutableString *item;

        // Assemble the columns and data types for the structure.
        for (RASqliteColumn *column in columns) {
            // The column have to be of type `RASqliteColumn`.
            if (![column isKindOfClass:[RASqliteColumn class]]) {
                [NSException raise:NSInvalidArgumentException
                            format:@"Column defined for table `%@` is not of type `RASqliteColumn.", table];
            }

            // Start with building the item with the column name and type.
            item = [[NSMutableString alloc] init];
            [item appendFormat:@"%@ %@", [column name], [column type]];

            // Check if the column should be unique.
            if ([column isUnique]) {
                [item appendString:@" UNIQUE"];
            }

            // Handle if the column should be nullable or not.
            if (![column isNullable]) {
                [item appendString:@" NOT"];
            }
            [item appendString:@" NULL"];

            // Check if the column should be a primary key.
            if ([column isPrimaryKey]) {
                [item appendString:@" PRIMARY KEY"];

                // Column have to be of type `integer` to use `autoincremental`.
                if ([column isAutoIncrement] && RASqliteInteger == [column numericType]) {
                    [item appendString:@" AUTOINCREMENT"];
                }
            } else {
                // If the column have a default value available, use it.
                // Have to check for nil since default value can be @0.
                if ([column defaultValue] != nil) {
                    [item appendFormat:@" DEFAULT `%@`", [column defaultValue]];
                }
            }

            // Add the item to the list of columns.
            [list addObject:item];
        }
        // Build the actual sql query for creating the table.
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)", table, [list componentsJoinedByString:@","]];
        RASqliteDebugLog(@"Create query: %@", sql);

        // Attempt to create the database table.
        created = [db execute:sql];
        if (created) {
            RASqliteDebugLog(@"Table `%@` have been created.", table);
        } else {
            RASqliteDebugLog(@"Table `%@` have not been created.", table);
        }
    }];

    return created;
}

- (BOOL)deleteTable:(NSString *)table {
    if (!table) {
        // Raise an exception, no valid table name.
        [NSException raise:NSInvalidArgumentException
                    format:@"Unable to remove table without valid name."];
    }

    // Keeps track on whether the table was created.
    BOOL __block removed = NO;

    [self queueWithBlock:^(RASqlite *db) {
        // Attempt to remove the database table.
        removed = [db execute:RASqliteSF(@"DROP TABLE IF EXISTS %@", table)];
        if (removed) {
            RASqliteDebugLog(@"Table `%@` have been removed.", table);
        } else {
            RASqliteDebugLog(@"Table `%@` have not been removed.", table);
        }
    }];

    return removed;
}

@end