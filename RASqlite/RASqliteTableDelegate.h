//
//  RASqliteTableDelegate.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-05-25.
//  Copyright (c) 2014-2016 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Available status flags for checking tables.
typedef NS_ENUM(short int, RASqliteTableCheckStatus) {
    /// The table is clean, i.e. nothing have been changed.
            RASqliteTableCheckStatusClean,

    /// The table do not exists.
            RASqliteTableCheckStatusNew,

    /// The table structure have been modified.
            RASqliteTableCheckStatusModified
};

/**
 Protocol for working with tables.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@protocol RASqliteTableDelegate <NSObject>

@optional

#pragma mark - Check

/**
 Executes before the table check is executed.

 @param table Name of the table to be checked.

 @return `YES` if check should continue, `NO` if the check should be skipped.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)beforeTableCheck:(NSString *)table;

/**
 Executes after the table check is exectued.

 @param table Name of the table that was checked.
 @param status Status of the table check.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)afterTableCheck:(NSString *)table withStatus:(RASqliteTableCheckStatus *)status;

@end