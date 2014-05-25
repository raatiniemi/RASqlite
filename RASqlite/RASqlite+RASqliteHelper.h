//
//  RASqlite+RASqliteHelper.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-05-25.
//  Copyright (c) 2014 Raatiniemi. All rights reserved.
//

#import "RASqlite.h"

@interface RASqlite (RASqliteHelper)

/**
 Retrieve id for the last inserted row.

 @return Id for the last inserted row.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 This method should only be called from within a block sent to either the `queueWithBlock:`
 or `queueTransactionWithBlock:` methods, otherwise there's a theoretical possibility
 that one query will be executed between the insert and the call to this method.
 */
- (NSNumber *)lastInsertId;

/**
 Returns the number of rows affected by the last query.

 @return Number of rows affected by the last query.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 This method should only be called from within a block sent to either the `queueWithBlock:`
 or `queueTransactionWithBlock:` methods, otherwise there's a theoretical possibility
 that one query will be executed between the execute-call and the call to this method.
 */
- (NSNumber *)rowCount;

@end