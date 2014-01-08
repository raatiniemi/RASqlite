//
//  NSMutableDictionary+RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-14.
//  Copyright (c) 2013-2014 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Implements a more consistent way of dealing with `nil` values and dictionaries.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface NSMutableDictionary (RASqlite)

/**
 Set an object for a column.

 @param name Name of the column.
 @param object Object for the column.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If the object is `nil` it will be committed to the dictionary as `NSNull`.
 */
- (void)setColumn:(NSString *)name withObject:(id)object;

@end