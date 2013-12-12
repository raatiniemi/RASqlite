//
//  RASqliteColumn.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

// -- -- Data types

/// Column data type for `NULL`.
static NSString *RASqliteNull = @"NULL";

/// Column data type for `INTEGER`.
static NSString *RASqliteInteger = @"INTEGER";

/// Column data type for `REAL`.
static NSString *RASqliteReal = @"REAL";

/// Column data type for `TEXT`.
static NSString *RASqliteText = @"TEXT";

/// Column data type for `BLOB`.
static NSString *RASqliteBlob = @"BLOB";

// TODO: Implement typedef enum for data types.

/**
 Check that the type is a valid column type.

 @param type Type to check.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
#define RASqliteColumnType(type)\
	[@[RASqliteInteger, RASqliteReal, RASqliteText, RASqliteBlob] containsObject:type]

/**
 Defines the column for the table, used while creating and checking structure.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @todo Implement support for foreign keys, with a helper struct or object.
 */
@interface RASqliteColumn : NSObject {
@protected
	NSString *_name;
	NSString *_type;
	id _defaultValue;

	BOOL _primaryKey;
	BOOL _autoIncrement;
	BOOL _unique;
	BOOL _nullable;
}

/// Stores the name of the column.
@property (atomic, readonly, strong) NSString *name;

/// Stores the data type for the column.
@property (atomic, readonly, strong) NSString *type;

// TODO: Handle validation of values related for data types.
/// Stores the default value for the column.
@property (atomic, readwrite, strong) id defaultValue;

/// Stores whether or not the column is a primary key.
@property (nonatomic, readwrite, getter = isPrimaryKey) BOOL primaryKey;

/// Stores whether or not the column is auto incremental.
@property (nonatomic, readwrite, getter = isAutoIncrement) BOOL autoIncrement;

/// Stores whether or not the column is unique.
@property (nonatomic, readwrite, getter = isUnique) BOOL unique;

/// Stores whether or not the column is nullable.
@property (nonatomic, readwrite, getter = isNullable) BOOL nullable;

#pragma mark - Initialization

/**
 Initialize with column name and type.

 @param name Name of the column.
 @param type Type of the column, must be a registered RASqlite data type.

 @code
 [[RASqliteColumn alloc] initWithName:@"id" type:RASqliteInteger];
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (instancetype)initWithName:(NSString *)name type:(NSString *)type;

@end