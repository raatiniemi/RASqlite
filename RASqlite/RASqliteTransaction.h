//
//  RASqliteTransaction.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-27.
//  Copyright © 2016 Raatiniemi. All rights reserved.
//

#ifndef RASqliteTransaction_h
#define RASqliteTransaction_h

/**
 Definition of available transaction types.

 @note
 More information about transaction types within sqlite can be found here:
 http://www.sqlite.org/lang_transaction.html
 */
typedef NS_ENUM(short int, RASqliteTransaction) {
            /// No locks are acquired on the database until the database is first accessed.
            RASqliteTransactionDeferred,

            /// Reserved locks are acquired on all database, without waiting for database access.
            RASqliteTransactionImmediate,

            /// An exclusive transaction causes EXCLUSIVE locks to be acquired on all databases.
            RASqliteTransactionExclusive
};

#endif /* RASqliteTransaction_h */
