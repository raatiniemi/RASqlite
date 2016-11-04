//
//  RASqliteColumn.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-27.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

// -- -- Data types

/// Available column data types.
typedef NS_ENUM(short int, RASqliteDataType) {
    /// Column data type for `NULL`.
            RASqliteNull,

    /// Column data type for `INTEGER`.
            RASqliteInteger,

    /// Column data type for `REAL`.
            RASqliteReal,

    /// Column data type for `TEXT`.
            RASqliteText,

    /// Column data type for `BLOB`.
            RASqliteBlob
};

/**
 Defines the column for the table, used while creating and checking structure.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @todo Implement support for foreign keys, with a helper struct or object.
 */
@interface RASqliteColumn : NSObject

/// Stores the name of the column.
@property(strong, atomic, readonly) NSString *name;

/// Stores the type of the column, in its numeric form.
@property(atomic, readonly) RASqliteDataType numericType;

/// Stores the type of the column.
@property(strong, atomic, readonly) NSString *type;

/// Stores the default value for the column.
@property(strong, nonatomic) id defaultValue;

/// Stores whether or not the column is a primary key.
@property(nonatomic, getter = isPrimaryKey) BOOL primaryKey;

/// Stores whether or not the column is auto incremental.
@property(nonatomic, getter = isAutoIncrement) BOOL autoIncrement;

/// Stores whether or not the column is unique.
@property(nonatomic, getter = isUnique) BOOL unique;

/// Stores whether or not the column is nullable.
@property(nonatomic, getter = isNullable) BOOL nullable;

#pragma mark - Initialization

/**
 Initialize with column name and type.

 @param name Name of the column.
 @param type Type of the column.

 @code
 [[RASqliteColumn alloc] initWithName:@"id" type:RASqliteInteger];
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (instancetype)initWithName:(NSString *)name type:(RASqliteDataType)type;

/**
 Initialize with column name, will use `RASqliteText` as data type.

 @param name Name of the column.

 @code
 [[RASqliteColumn alloc] initWithName:@"id"];
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (instancetype)initWithName:(NSString *)name;

/**
 Initialize column without name and type, will raise an exception.

 @throws NSInvalidArgumentException Since no name have been supplied.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (instancetype)init;

#pragma mark - Setters

/**
 Stores the default value for the column.

 @param defaultValue Value to be used as column default value.

 @throws NSException If value is not correct data type.
 @throws NSException If column type is blob, not yet implemented.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)setDefaultValue:(id)defaultValue;

/**
 Stores whether or not the column is a primary key.

 @param primaryKey `YES` if the column should be primary key, otherwise `NO`.

 @throws NSException If column is nullable.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)setPrimaryKey:(BOOL)primaryKey;

/**
 Stores whether or not the column is auto incremental.

 @param autoIncrement `YES` if column should auto increment, otherwise `NO`.

 @throws NSException If column is not type `RASqliteInteger`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)setAutoIncrement:(BOOL)autoIncrement;

/**
 Stores whether or not the column is unique.

 @param unique `YES` if the column should be unique, otherwise `NO`.

 @throws NSException If column is nullable.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)setUnique:(BOOL)unique;

/**
 Stores whether or not the column is nullable.

 @param nullable `YES` if coulmn should be nullable, otherwise `NO`.

 @throws NSException If column is primary key.
 @throws NSException If column is unique.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)setNullable:(BOOL)nullable;

@end