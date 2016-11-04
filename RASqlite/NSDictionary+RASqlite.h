//
//  NSDictionary+RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-14.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Implements a more consistent way of dealing with `nil` values and dictionaries.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface NSDictionary (RASqlite)

/**
 Get object for the column.

 @param name Name of the column.

 @return Object for the column.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If the column value is empty (e.g. `nil`) or the column do not exists, `NSNull`
 object will be returned instead.
 */
- (id)getColumn:(NSString *)name;

/**
 Check whether a column exists within the dictionary.

 @param name Name of the column.

 @return `YES` if the column exists, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)hasColumn:(NSString *)name;

@end