//
//  RASqliteModel.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "RASqlite.h"
#import "RASqliteError.h"

@interface RASqliteModel : NSObject {
/**
 Queue on which the queries will be executing.
 */
@protected dispatch_queue_t _queue;
}

/**
 Stores the first occurred error, `nil` if none has occurred.
 */
@property (nonatomic, readwrite, strong) RASqliteError *error;

/**
 Stores the defined structure for the database tables.
 */
@property (nonatomic, readonly, copy) NSDictionary *structure;

#pragma mark - Initialization

/**
 Initialize with the name of the database file.

 @param name Name of the database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (id)initWithName:(NSString *)name;

#pragma mark - Database

/**
 Retrieves the database instance.

 @return Database instance, or `nil` if none is available.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (sqlite3 *)database;

/**
 Retrieve the absolute path for the database file.

 @return Absolute path for database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSString *)path;

/**
 Open database with flags.

 @param flags Flags for how to open the database.

 @return `nil` if database was successfully opened, otherwise an error object.

 @code
 RASqliteError *error = [model openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE];
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 This method should only be called if none default flags are required. Otherwise,
 the `open`-method will be automatically called before performing a query, unless
 the database is already open.
 */
- (RASqliteError *)openWithFlags:(int)flags;

/**
 Open database with default flags.

 @return `nil` if database was successfully opened, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 This method should not be called manually. It'll be called automatically before
 performing a query, unless the database is already open.

 @par
 The default flags are `SQLITE_OPEN_CREATE` and `SQLITE_OPEN_READWRITE`, which
 means that if the file do not exists, it will be created. And, it's open for
 both read and write operations.
 */
- (RASqliteError *)open;

/**
 Close the database.
 
 @return `nil` if database was successfully closed, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (RASqliteError *)close;

#pragma mark - Table

// TODO: Implement methods for creating, checking and deleting tables.

#pragma mark - Query
#pragma mark -- Fetch

/**
 Fetch a result set from the database, with parameters.
 
 @param sql Query to perform against the database.
 @param params Parameters to bind to the query.
 
 @code
 [self fetch:@"SELECT foo FROM bar WHERE id = ? AND baz = ?" withParams:@[@53, @"qux"]];
 @endcode

 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @autor Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The first index within the params array will bind against the first question mark
 within the SQL query. The second, to the second question mark, etc.
 */
- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params;

/**
 Fetch a result set from the database, with a parameter.

 @param sql Query to perform against the database.
 @param param Parameter to bind to the query.

 @code
 [self fetch:@"SELECT foo FROM bar WHERE id = ?" withParam:@53];
 @endcode

 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @autor Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSArray *)fetch:(NSString *)sql withParam:(id)param;

/**
 Fetch a result set from the database, without parameters.

 @param sql Query to perform against the database.

 @code
 [self fetch:@"SELECT foo FROM bar"];
 @endcode

 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @autor Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSArray *)fetch:(NSString *)sql;

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params;

- (NSDictionary *)fetchRow:(NSString *)sql withParam:(id)param;

- (NSDictionary *)fetchRow:(NSString *)sql;

#pragma mark -- Update

- (RASqliteError *)execute:(NSString *)sql withParams:(NSArray *)params;

- (RASqliteError *)execute:(NSString *)sql withParam:(id)param;

- (RASqliteError *)execute:(NSString *)sql;

#pragma mark - Transaction

// TODO: Implement support for handling transactions.

@end