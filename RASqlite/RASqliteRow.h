//
//  RASqliteRow.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Represent a row within a result set.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqliteRow : NSObject

#pragma mark - Initialization

/**
 Initialize the row with number of columns.

 @param columns Number of columns for the row.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
+ (instancetype)columns:(NSUInteger)columns;

#pragma mark - Container manipulation

/**
 Get value from column.

 @param name Name of the column.

 @return Value for the column.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If the value is empty (e.g. `nil`) or the column do not exists, `NSNull null`
 will be returned instead.
 */
- (id)getColumn:(NSString *)name;

/**
 Set value for column.

 @param name Name of the column.
 @param value Value for the column.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If the value is `nil` it will be committed to the container as `NSNull null`.
 */
- (void)setColumn:(NSString *)name withValue:(id)value;

/**
 Check whether a column exists or not.

 @param name Name of the column.

 @return `YES` if column exists, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)hasColumn:(NSString *)name;

/**
 Relay the `count`-call to the dictionary.

 @return Number of columns within the row.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSUInteger)count;

@end