//
//  RASqliteColumn.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RASqliteColumn.h"

// -- -- Import

#import "RASqlite.h"

/**
 Defines the column for the table, used while creating and checking structure.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqliteColumn () {
}

/// Stores the name of the column.
@property (atomic, readwrite, strong) NSString *name;

/// Stores the data type for the column.
@property (atomic, readwrite, strong) NSString *type;

@end

@implementation RASqliteColumn

@synthesize name = _name;

@synthesize type = _type;

@synthesize defaultValue = _defaultValue;

@synthesize primaryKey = _primaryKey;

@synthesize autoIncrement = _autoIncrement;

@synthesize unique = _unique;

@synthesize nullable = _nullable;

#pragma mark - Initialization

- (instancetype)initWithName:(NSString *)name type:(NSString *)type
{
	if ( self = [super init] ) {
		// Verify the supplied column name, can not be `nil`.
		if ( name == nil ) {
			[NSException raise:NSInvalidArgumentException
						format:@"The supplied column name can not be `nil`."];
		}

		// Verify the supplied column type, can not be `nil`.
		if ( type == nil ) {
			[NSException raise:NSInvalidArgumentException
						format:@"The supplied column type can not be `nil`."];
		}

		// Check that the column type is a valid column type.
		if ( !RASqliteColumnType(type) ) {
			[NSException raise:NSInvalidArgumentException
						format:@"The supplied data type is not a valid column type."];
		}

		[self setName:name];
		[self setType:type];
	}
	return self;
}

@end