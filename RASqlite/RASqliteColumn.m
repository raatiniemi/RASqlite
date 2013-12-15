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

/// Stores the type of the column, in its numeric form.
@property (atomic, readwrite) RASqliteDataType numericType;

/// Stores the type of the column.
@property (atomic, readwrite, strong) NSString *type;

@end

@implementation RASqliteColumn

@synthesize name = _name;

@synthesize numericType = _numericType;

@synthesize type = _type;

@synthesize defaultValue = _defaultValue;

@synthesize primaryKey = _primaryKey;

@synthesize autoIncrement = _autoIncrement;

@synthesize unique = _unique;

@synthesize nullable = _nullable;

#pragma mark - Initialization

- (instancetype)initWithName:(NSString *)name type:(RASqliteDataType)type
{
	if ( self = [super init] ) {
		// Verify the supplied column name, can not be `nil`.
		if ( name == nil ) {
			[NSException raise:NSInvalidArgumentException
						format:@"The supplied column name can not be `nil`."];
		}

		// Check that the column type is a valid column type.
		switch (type) {
			case RASqliteInteger:
				[self setType:@"INTEGER"];
				_defaultValue = @0;
				break;

			case RASqliteReal:
				[self setType:@"REAL"];
				_defaultValue = @0;
				break;

			case RASqliteBlob:
				[self setType:@"BLOB"];
				break;

			case RASqliteText:
				[self setType:@"TEXT"];
				break;

			default:
				[NSException raise:NSInvalidArgumentException
							format:@"The supplied data type is not a valid column type."];
		}
		
		[self setName:name];
		[self setNumericType:type];

		// Set the default values for the column constraints.
		_primaryKey = NO;
		_autoIncrement = NO;
		_unique = NO;
		_nullable = NO;
	}
	return self;
}

#pragma mark - Setters

- (void)setDefaultValue:(id)defaultValue
{
	if ( RASqliteInteger == [self numericType] || RASqliteReal == [self numericType] ) {
		if ( ![defaultValue isKindOfClass:[NSNumber class]] ) {
			[NSException raise:RASqliteColumnConstrainException
						format:@"Default value for column `%@` must be of type `NSNumber`.", [self name]];
		}
	} else if ( RASqliteText == [self numericType] ) {
		if ( ![defaultValue isKindOfClass:[NSString class]] ) {
			[NSException raise:RASqliteColumnConstrainException
						format:@"Default value for column `%@` must be of type `NSString`.", [self name]];
		}
	} else if ( RASqliteBlob == [self numericType] ) {
		// TODO: How should default value for `blob` be handled?
		// Should it be allowed to define default values for `blob`, might be a
		// bad idea in regard to performance and size.
		[NSException raise:RASqliteIncompleteImplementationException
					format:@"Default value support for data type `blob` have not been implemented."];
	}

	_defaultValue = defaultValue;
}

- (void)setPrimaryKey:(BOOL)primaryKey
{
	if ( [self isNullable] ) {
		[NSException raise:RASqliteColumnConstrainException
					format:@"Primary key columns can not be `nullable`."];
	}

	_primaryKey = primaryKey;
}

- (void)setAutoIncrement:(BOOL)autoIncrement
{
	// Verify that the column is a valid data type.
	if ( RASqliteInteger != [self numericType] ) {
		[NSException raise:RASqliteColumnConstrainException
					format:@"Auto increment is only available for `integer` columns."];
	}

	_autoIncrement = autoIncrement;
}

- (void)setUnique:(BOOL)unique
{
	if ( [self isNullable] ) {
		[NSException raise:RASqliteColumnConstrainException
					format:@"Unique columns can not be `nullable`."];
	}

	_unique = unique;
}

- (void)setNullable:(BOOL)nullable
{
	if ( [self isPrimaryKey] ) {
		[NSException raise:RASqliteColumnConstrainException
					format:@"Nullable can not be set to primary key columns."];
	}

	if ( [self isUnique] ) {
		[NSException raise:RASqliteColumnConstrainException
					format:@"Nullable can not be set to unique columns."];
	}

	_nullable = nullable;
}

@end