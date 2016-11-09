//
//  RASqliteMapper.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-09.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import "RASqliteMapper.h"

#import "NSMutableDictionary+RASqlite.h"

@implementation RASqliteMapper

+ (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement {
    NSUInteger count = (NSUInteger) sqlite3_column_count(*statement);
    NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:count];

    const char *name;
    NSString *column;

    unsigned int index;
    int type;
    // Loop through the columns.
    for (index = 0; index < count; index++) {
        name = sqlite3_column_name(*statement, index);
        column = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

        // Check which column type the current index is and bind the column value.
        type = sqlite3_column_type(*statement, index);
        switch (type) {
            case SQLITE_INTEGER: {
                // TODO: Test on 32-bit machine.
                long long int value = sqlite3_column_int64(*statement, index);
                [row setColumn:column withObject:@(value)];
                break;
            }
            case SQLITE_FLOAT: {
                double value = sqlite3_column_double(*statement, index);
                [row setColumn:column withObject:@(value)];
                break;
            }
            case SQLITE_BLOB: {
                // Retrieve the value and the number of bytes for the blob column.
                const void *value = (void *) sqlite3_column_blob(*statement, index);
                NSUInteger bytes = (NSUInteger) sqlite3_column_bytes(*statement, index);
                [row setColumn:column withObject:[NSData dataWithBytes:value length:bytes]];
                break;
            }
            case SQLITE_NULL: {
                [row setColumn:column withObject:[NSNull null]];
                break;
            }
            case SQLITE_TEXT:
            default: {
                // Sqlite do not seem to fully support UTF-16 yet, so no need to
                // implement support for the `sqlite3_column_text16` functionality.
                const char *value = (const char *) sqlite3_column_text(*statement, index);
                [row setColumn:column withObject:[NSString stringWithCString:value encoding:NSUTF8StringEncoding]];
                break;
            }
        }
    }

    return row;
}

@end
