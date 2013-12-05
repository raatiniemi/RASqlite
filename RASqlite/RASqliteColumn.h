//
//  RASqliteColumn.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

// -- -- Import

#import "RASqlite.h"

/**
 Defines the column for the table, used while creating and checking structure.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqliteColumn : NSObject {
@protected
	NSString *_name;
	NSString *_type;
	id _defaultValue;

	BOOL _primaryKey;
}

/// Stores the name of the column.
@property (nonatomic, readonly, strong) NSString *name;

/// Stores the data type for the column.
@property (nonatomic, readonly, strong) NSString *type;

/// Stores the default value for the column.
@property (nonatomic, readwrite, strong) id defaultValue;

/// Stores whether or not the column is a primary key.
@property (nonatomic, readwrite, getter = isPrimaryKey) BOOL primaryKey;

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