//
//  RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

// -- -- Constants

/**
 Format for the name of the query threads.
 */
#define kRASqliteThreadFormat @"me.raatiniemi.rasqlite.%@"

/**
 Retrieves the name of the currently executed thread.
 
 @note
 Will be used to determind whether we need to dispatch a sync thread for the
 queries, or if the sync thread already have been dispatched.
 */
#define RASqliteQueueLabel dispatch_queue_get_label(dispatch_get_current_queue())

// -- -- RASqlite

#import "RASqliteError.h"

@interface RASqlite : NSObject {
@protected dispatch_queue_t _queue;

@protected RASqliteError *_error;
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

 @note
 Method is mainly design for iOS development. It will create the absolute path
 for the database to the applications document directory, the name will be used
 as the database filename.
 */
- (instancetype)initWithName:(NSString *)name;

/**
 Initialize with the absolute path for the database file.

 @param path Absolute path for the database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (instancetype)initWithPath:(NSString *)path;

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
 if ( error ) {
	// An error has occurred, handle it.
 }
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
 NSArray *results = [self fetch:@"SELECT foo FROM bar WHERE baz = ? AND qux = ?" withParams:@[@53, @"id"]];
 if ( results ) {
	// Do something with the results.
 } else if ( ![self error] ) {
	// Nothing was found.
 } else {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode

 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @autor Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The first index within the params array will bind against the first question
 mark within the SQL query. The second, to the second question mark, etc.
 
 @par
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params;

/**
 Fetch a result set from the database, with a parameter.

 @param sql Query to perform against the database.
 @param param Parameter to bind to the query.

 @code
 NSArray *results = [self fetch:@"SELECT foo FROM bar WHERE baz = ?" withParam:@"qux"];
 if ( results ) {
	// Do something with the results.
 } else if ( ![self error] ) {
	// Nothing was found.
 } else {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode

 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @autor Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (NSArray *)fetch:(NSString *)sql withParam:(id)param;

/**
 Fetch a result set from the database, without parameters.

 @param sql Query to perform against the database.

 @code
 NSArray *results = [self fetch:@"SELECT foo FROM bar"];
 if ( results ) {
	// Do something with the results.
 } else if ( ![self error] ) {
	// Nothing was found.
 } else {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode

 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @autor Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (NSArray *)fetch:(NSString *)sql;

/**
 Fetch a row from the database, with parameters.

 @param sql Query to perform against the database.
 @param params Parameters to bind to the query.

 @code
 NSDictionary *row = [self fetchRow:@"SELECT foo FROM bar WHERE baz = ? AND qux = ? LIMIT 1" withParams:@[@53, @"id"]];
 if ( row ) {
	// Do something with the results.
 } else if ( ![self error] ) {
	// Nothing was found.
 } else {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode
 
 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The first index within the params array will bind against the first question
 mark within the SQL query. The second, to the second question mark, etc.
 
 @par
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params;

/**
 Fetch a row from the database, with a parameter.

 @param sql Query to perform against the database.
 @param param Parameter to bind to the query.

 @code
 NSDictionary *row = [self fetchRow:@"SELECT foo FROM bar WHERE qux = ? LIMIT 1" withParam:@53];
 if ( row ) {
	// Do something with the results.
 } else if ( ![self error] ) {
	// Nothing was found.
 } else {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode

 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (NSDictionary *)fetchRow:(NSString *)sql withParam:(id)param;

/**
 Fetch a row from the database, without parameters.

 @param sql Query to perform against the database.

 @code
 NSDictionary *row = [self fetchRow:@"SELECT foo FROM bar ORDER BY baz ASC LIMIT 1"];
 if ( row ) {
	// Do something with the results.
 } else if ( ![self error] ) {
	// Nothing was found.
 } else {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode

 @return Result from query, or `nil` if nothing was found or an error has occurred.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (NSDictionary *)fetchRow:(NSString *)sql;

#pragma mark -- Update

/**
 Execute update query, with parameters.

 @param sql Query to perform against the database.
 @param params Parameters to bind to the query.

 @code
 BOOL updated = [self execute:@"UPDATE foo SET bar='baz' WHERE id = ? AND qux = ?" withParams:@[@13, @37]];
 if ( !updated ) {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode

 @return `YES` if query executed successfully, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (BOOL)execute:(NSString *)sql withParams:(NSArray *)params;

/**
 Execute update query, with a parameter.

 @param sql Query to perform against the database.
 @param param Parameter to bind to the query.

 @code
 BOOL updated = [self execute:@"UPDATE foo SET bar='baz' WHERE qux = ?" withParam:@35];
 if ( !updated ) {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode

 @return `YES` if query executed successfully, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (BOOL)execute:(NSString *)sql withParam:(id)param;

/**
 Execute update query, without parameters.

 @param sql Query to perform against the database.

 @code
 if ( ![self execute:@"UPDATE foo SET bar='baz'"] ) {
	// An error has occurred. Handle the error, and reset the error variable.
	// Otherwise, the error will block any futher queries with the instanisated model.
	[self setError:nil];
 }
 @endcode

 @return `YES` if query executed successfully, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 
 @note
 The method will determind whether it'll need to dispatch to the queue, or if
 it's already executing on the query queue. I.e. the method can be called from
 within the `queueWithBlock:` and `queueTransactionWithBlock:` methods.
 */
- (BOOL)execute:(NSString *)sql;

#pragma mark -- Queue

/**
 Execute a block within the query thread.

 @param block Block to be executed.

 @code
 NSDictionary __block *row;
 [self queueWithBlock:^(RASqlite *db) {
	row = [db fetchRow:@"SELECT foo FROM bar WHERE baz = ?" withParam:@"qux"];
 }];
 // Do something with row.
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)queueWithBlock:(void (^)(RASqlite *db))block;

/**
 Execute a transaction block on the query thread.

 @param block Block to be executed.

 @code
 [database queueTransactionWithBlock:^(RASqlite *db, BOOL *commit) {
	commit = [db execute:@"DELETE FROM foo WHERE bar = ?" withParam:@"baz"];
	if ( commit ) {
		commit = [db execute:@"DELETE FROM bar WHERE baz = ?" withParam:@"qux"];
	}
 }];
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)queueTransactionWithBlock:(void (^)(RASqlite *db, BOOL **commit))block;

#pragma mark - Transaction

// TODO: Implement methods for commit, rollback and transaction types.

@end