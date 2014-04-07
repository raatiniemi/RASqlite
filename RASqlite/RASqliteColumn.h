//
//  RASqliteColumn.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-27.
//  Copyright (c) 2013-2014 Raatiniemi. All rights reserved.
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
@interface RASqliteColumn : NSObject {
@protected
	NSString *_name;
	RASqliteDataType _numericType;
	NSString *_type;
	id _defaultValue;

	BOOL _primaryKey;
	BOOL _autoIncrement;
	BOOL _unique;
	BOOL _nullable;
}

/// Stores the name of the column.
@property (strong, atomic, readonly) NSString *name;

/// Stores the type of the column, in its numeric form.
@property (atomic, readonly) RASqliteDataType numericType;

/// Stores the type of the column.
@property (strong, atomic, readonly) NSString *type;

/// Stores the default value for the column.
@property (strong, nonatomic) id defaultValue;

/// Stores whether or not the column is a primary key.
@property (nonatomic, getter = isPrimaryKey) BOOL primaryKey;

/// Stores whether or not the column is auto incremental.
@property (nonatomic, getter = isAutoIncrement) BOOL autoIncrement;

/// Stores whether or not the column is unique.
@property (nonatomic, getter = isUnique) BOOL unique;

/// Stores whether or not the column is nullable.
@property (nonatomic, getter = isNullable) BOOL nullable;

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

@end