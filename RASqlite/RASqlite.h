//
//  RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

// -- -- Threading

/// Format for the name of the query threads.
#define kRASqliteThreadFormat @"me.raatiniemi.rasqlite.%@"

/// The key used for setting/getting the name for the dispatch queue.
#define kRASqliteKeyQueueName "me.raatiniemi.rasqlite.queue.name"

// -- -- Data types

/// Column data type for `NULL`.
static const NSString *RASqliteNull = @"NULL";

/// Column data type for `INTEGER`.
static const NSString *RASqliteInteger = @"INTEGER";

/// Column data type for `REAL`.
static const NSString *RASqliteReal = @"REAL";

/// Column data type for `TEXT`.
static const NSString *RASqliteText = @"TEXT";

/// Column data type for `BLOB`.
static const NSString *RASqliteBlob = @"BLOB";

/**
 Check if the specified type is a valid data type.

 @param type Type to check.

 @return `YES` if type is valid, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
#define RASqliteDataType(type) [@[RASqliteNull, RASqliteInteger, RASqliteReal, RASqliteText, RASqliteBlob] containsObject:type]

// -- -- Transaction

/**
 Definition of available transaction types.

 @note
 More information about transaction types within sqlite can be found here:
 http://www.sqlite.org/lang_transaction.html
 */
typedef enum {
	/// No locks are acquired on the database until the database is first accessed.
	RASqliteTransactionDeferred,

	/// Reserved locks are acquired on all database, without waiting for database access.
	RASqliteTransactionImmediate,

	/// An exclusive transaction causes EXCLUSIVE locks to be acquired on all databases.
	RASqliteTransactionExclusive
} RASqliteTransaction;

// -- -- Logging

/// Definition of available log levels
typedef enum {
	/// Debug-level messages.
	RASqliteLogLevelDebug,

	/// Informational-level messages.
	RASqliteLogLevelInfo,

	/// Warning-level messages.
	RASqliteLogLevelWarning,

	/// Error-level messages.
	RASqliteLogLevelError
} RASqliteLogLevel;

#if DEBUG
/// Stores the level of logging within the library.
static const RASqliteLogLevel _RASqliteLogLevel = RASqliteLogLevelDebug;

// Only define the logging methods if they have not been defined. This way it's
// possible to override the logging method if needed from the application.
// TODO: Instead of defining a macro, define a real function.
#ifndef RASqliteLog
#define RASqliteLog(level, format, ...)\
do {\
	if ( level >= _RASqliteLogLevel ) {\
		NSLog(\
			(@"<%@:(%d)> " format),\
			[[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
			__LINE__,\
			##__VA_ARGS__\
		);\
	}\
} while(0)
#endif
#else
// If debug is not enabled, nothing should reach the debug log.
#ifndef RASqliteLog
#define RASqliteLog(level, format, ...) do { } while(0)
#endif
#endif

// -- -- Import

#import "NSDictionary+RASqlite.h"

/**
 RASqlite is a simple library for working with SQLite databases on iOS and Mac OS X.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqlite : NSObject {
@protected NSError *_error;
}

/// Stores the first occurred error, `nil` if none has occurred.
@property (atomic, readwrite, strong) NSError *error;

#pragma mark - Initialization

/**
 Initialize with the absolute path for the database file.

 @param path Absolute path for the database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If the directory do not exists, it will be created.
 */
- (instancetype)initWithPath:(NSString *)path;

/**
 Initialize with the name of the database file.

 @param name Name of the database file.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If the directory do not exists, it will be created.
 */
- (instancetype)initWithName:(NSString *)name;

#pragma mark - Database

/// Stores the defined structure for the database tables.
@property (nonatomic, readonly, copy) NSDictionary *structure;

/**
 Set the database instance.

 @param database Database instance.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)setDatabase:(sqlite3 *)database;

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
 NSError *error = [model openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE];
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
- (NSError *)openWithFlags:(int)flags;

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
- (NSError *)open;

/**
 Close the database.
 
 @return `nil` if database was successfully closed, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)close;

#pragma mark - Table

/**
 Check structure for the database.

 @return `YES` if database structure is as defined, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)check;

/**
 Check structure for database table.

 @param table Name of the table to check.
 @param columns Dictionary with column names and their data types.

 @return `YES` if table structure is as defined, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)checkTable:(NSString *)table withColumns:(NSDictionary *)columns;

/**
 Create the database structure.

 @return `YES` if database structure have been created, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)create;

/**
 Create the table structure.

 @param table Name of the table to create.
 @param columns Dictionary with column names and their data types.

 @return `YES` if table structure is created, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)createTable:(NSString *)table withColumns:(NSDictionary *)columns;

/**
 Delete the database table.

 @param table Name of the table to delete.

 @return `YES` if table is deleted, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)deleteTable:(NSString *)table;

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

 @param transaction The type of the transaction.
 @param block Block to be executed.

 @code
 [database queueTransaction:RASqliteTransactionDeferred withBlock:^(RASqlite *db, BOOL *commit) {
	commit = [db execute:@"DELETE FROM foo WHERE bar = ?" withParam:@"baz"];
	if ( commit ) {
		commit = [db execute:@"DELETE FROM bar WHERE baz = ?" withParam:@"qux"];
	}
 }];
 @endcode

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)queueTransaction:(RASqliteTransaction)transaction withBlock:(void (^)(RASqlite *db, BOOL **commit))block;

/**
 Execute a deferred transaction block on the query thread.

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

@end