//
//  RASqliteBinder.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-09.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import "RASqliteBinder.h"

#import "RASqlite.h"
#import "NSError+RASqlite.h"

@implementation RASqliteBinder

+ (NSError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement {
    NSError *error;

    // Get the pointer for the method, performance improvement.
    SEL selector = @selector(isKindOfClass:);

    typedef BOOL (*isClass)(id, SEL, Class);
    isClass isKindOfClass = (isClass) [self methodForSelector:selector];

    int code = SQLITE_OK;
    unsigned int index = 1;
    for (id column in columns) {
        if (isKindOfClass(column, selector, [NSString class])) {
            // Sqlite do not seem to fully support UTF-16 yet, so no need to
            // implement support for the `sqlite3_bind_text16` functionality.
            code = sqlite3_bind_text(*statement, index, [column UTF8String], -1, SQLITE_TRANSIENT);
        } else if (isKindOfClass(column, selector, [NSNumber class])) {
            const char *type = [column objCType];
            if (strcmp(type, @encode(double)) == 0 || strcmp(type, @encode(float)) == 0) {
                // Both double and float should be bound as double.
                code = sqlite3_bind_double(*statement, index, [column doubleValue]);
            } else if (strcmp(type, @encode(long)) == 0 || strcmp(type, @encode(long long)) == 0) {
                code = sqlite3_bind_int64(*statement, index, [column longLongValue]);
            } else {
                // Every data type that is not specified should be bound as an int.
                code = sqlite3_bind_int(*statement, index, [column intValue]);
            }
        } else if (isKindOfClass(column, selector, [NSNull class])) {
            code = sqlite3_bind_null(*statement, index);
        } else {
            unsigned int length = (unsigned int) [column length];
            code = sqlite3_bind_blob(*statement, index, [column bytes], length, SQLITE_TRANSIENT);
        }

        // Check if the binding of the column was successful.
        if (code != SQLITE_OK) {
            NSString *message = RASqliteSF(@"Unable to bind type `%@`.", [column class]);
            RASqliteErrorLog(@"%@", message);

            error = [NSError code:RASqliteErrorBind message:message];
            break;
        }
        index++;
    }

    return error;
}

@end
