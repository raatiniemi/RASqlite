//
//  RASqliteMapper.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-09.
//  Copyright (c) 2016 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface RASqliteMapper : NSObject

/**
 Fetch the retrieved columns from the SQL query.

 @param statement Statement from which to retrieve the columns.

 @return Row with the column names and their values.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The dictionary will contain the Foundation representations of the SQLite data types,
 e.g. `SQLITE_INTEGER` will be `NSNumber`, `SQLITE_NULL` will be `NSNull`, etc.
 */
+ (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement;

@end
