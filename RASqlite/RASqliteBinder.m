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

typedef BOOL (*isClass)(id, SEL, Class);

@interface RASqliteBinder () {
@private
    NSArray *_columns;
    sqlite3_stmt **_statement;

    SEL _selector;
    isClass _isKindOfClass;
}

- (instancetype)initWithColumns:(NSArray *)columns andStatement:(sqlite3_stmt **)statement;

- (NSError *)bind;

- (int)bindColumn:(id)column toIndex:(unsigned int)index;

- (int)bindNullToIndex:(unsigned int)index;

- (int)bindText:(id)column toIndex:(unsigned int)index;

- (int)bindNumber:(id)column toIndex:(unsigned int)index;

- (int)bindBlob:(id)column toIndex:(unsigned int)index;

@end

@implementation RASqliteBinder

+ (NSError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement {
    RASqliteBinder *binder = [[RASqliteBinder alloc] initWithColumns:columns andStatement:statement];
    return [binder bind];
}

- (instancetype)initWithColumns:(NSArray *)columns andStatement:(sqlite3_stmt **)statement {
    if ( self = [super init] ) {
        _columns = columns;
        _statement = statement;

        // Get the pointer for the method, performance improvement.
        _selector = @selector(isKindOfClass:);
        _isKindOfClass = (isClass) [self methodForSelector:_selector];
    }

    return self;
}

- (NSError *)bind {
    NSError *error;

    unsigned int index = 1;
    for (id column in _columns) {
        int code = [self bindColumn:column toIndex:index];
        if (code == SQLITE_OK) {
            index++;
            continue;
        }

        NSString *message = RASqliteSF(@"Unable to bind type `%@`.", [column class]);
        RASqliteErrorLog(@"%@", message);

        error = [NSError code:RASqliteErrorBind message:message];
        break;
    }

    return error;
}

- (int)bindColumn:(id)column toIndex:(unsigned int)index {
    if (_isKindOfClass(column, _selector, [NSNull class])) {
        return [self bindNullToIndex:index];
    }

    if (_isKindOfClass(column, _selector, [NSString class])) {
        return [self bindText:column toIndex:index];
    }

    if (_isKindOfClass(column, _selector, [NSNumber class])) {
        return [self bindNumber:column toIndex:index];
    }

    return [self bindBlob:column toIndex:index];
}

- (int)bindNullToIndex:(unsigned int)index {
    return sqlite3_bind_null(*_statement, index);
}

- (int)bindText:(id)column toIndex:(unsigned int)index {
    // Sqlite do not seem to fully support UTF-16 yet, so no need to
    // implement support for the `sqlite3_bind_text16` functionality.
    return sqlite3_bind_text(*_statement, index, [column UTF8String], -1, SQLITE_TRANSIENT);
}

- (int)bindNumber:(id)column toIndex:(unsigned int)index {
    const char *type = [column objCType];

    if (strcmp(type, @encode(double)) == 0 || strcmp(type, @encode(float)) == 0) {
        return sqlite3_bind_double(*_statement, index, [column doubleValue]);
    }

    if (strcmp(type, @encode(long)) == 0 || strcmp(type, @encode(long long)) == 0) {
        return sqlite3_bind_int64(*_statement, index, [column longLongValue]);
    }

    return sqlite3_bind_int(*_statement, index, [column intValue]);
}

- (int)bindBlob:(id)column toIndex:(unsigned int)index {
    unsigned int length = (unsigned int) [column length];

    return sqlite3_bind_blob(*_statement, index, [column bytes], length, SQLITE_TRANSIENT);
}

@end
