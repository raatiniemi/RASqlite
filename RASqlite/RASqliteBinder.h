//
//  RASqliteBinder.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-09.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import <sqlite3.h>

@interface RASqliteBinder : NSObject

/**
 Bind columns to a statement.

 @param columns Columns to bind.
 @param statement Statement to be bound.

 @return An error if one occurred, otherwise `nil`.
 */
+ (NSError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement;

- (id)init __unavailable;

@end
