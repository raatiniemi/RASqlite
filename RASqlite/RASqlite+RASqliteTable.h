//
//  RASqlite+RASqliteTable.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-05-24.
//  Copyright (c) 2014-2016 Raatiniemi. All rights reserved.
//

#import "RASqlite.h"
#import "RASqliteTableDelegate.h"

@interface RASqlite (RASqliteTable) <RASqliteTableDelegate>

/**
 Check structure for the database.

 @return `YES` if database structure is as defined, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)check;

/**
 Check structure for database table.

 @param table Name of the table to check.
 @param columns Array with column definitions.

 @return `YES` if table structure is as defined, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)checkTable:(NSString *)table withColumns:(NSArray *)columns;

/**
 Check structure for database table.

 @param table Name of the table to check.
 @param columns Array with column definitions.
 @param status Status of the table.

 @return `YES` if table structure is as defined, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)checkTable:(NSString *)table withColumns:(NSArray *)columns status:(RASqliteTableCheckStatus **)status;

/**
 Create the database structure.

 @return `YES` if database structure have been created, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)create;

/**
 Create the table structure.

 @param table Name of the table to create.
 @param columns Array with column definitions.

 @return `YES` if table structure is created, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)createTable:(NSString *)table withColumns:(NSArray *)columns;

/**
 Delete the database table.

 @param table Name of the table to delete.

 @return `YES` if table is deleted, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)deleteTable:(NSString *)table;

@end