//
//  RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

// Available SQLite data types.
#define kRASqliteNull		@"NULL"
#define kRASqliteInteger	@"INTEGER"
#define kRASqliteReal		@"REAL"
#define kRASqliteText		@"TEXT"
#define kRASqliteBlob		@"BLOB"

// Debug is always enabled unless otherwise instructed by the application.
#ifndef kRASqliteDebugEnabled
#define kRASqliteDebugEnabled 1
#endif

#if kRASqliteDebugEnabled
#define RASqliteLog(format, ...)\
	NSLog(\
		(@"<%@:(%d)> " format),\
		[[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
		__LINE__,\
		##__VA_ARGS__\
	);
#else
#define RASqliteLog(...)
#endif

typedef enum {
	RASqliteTransactionDeferred,
	RASqliteTransactionImmediate,
	RASqliteTransactionExclusive,
} RASqliteTransaction;

@interface RASqlite : NSObject {
@protected NSString *_name;

@protected sqlite3 *_database;

@protected NSError *_error;
}

@property (nonatomic, readonly, strong) NSString *name;

@property (nonatomic, readwrite) sqlite3 *database;

@property (nonatomic, readonly, strong) NSDictionary *structure;

@property (nonatomic, readwrite, strong) NSError *error;

/**
 Initialize with the database name.

 @param name Name of the database.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (id)initWithName:(NSString *)name;

- (NSError *)open;

- (NSError *)close;

/**
 Attempt to create the defined table structure.

 @return `nil` if the database structure is created, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)create;

/**
 Create table with column structure.

 @param table Name of the table to create.
 @param columns Dictionary with column name and data type.

 @code
 [self createTable:@"foo" withColumns:@{@"id":kRASqliteInteger}]
 @endcode

 @return `nil` if the table is created, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The column named `id` will be `PRIMARY KEY`, if it´s specified as `kRASqliteInteger`.

 @par
 Columns of the type `kRASqliteInteger` will have `0` with as default value.
 */
- (NSError *)createTable:(NSString *)table withColumns:(NSDictionary *)columns;

/**
 Delete table from database.

 @param table Name of the table to delete.

 @code
 [self deleteTable:@"foo"]
 @endcode

 @return `nil` if the table is deleted, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)deleteTable:(NSString *)table;

/**
 Check the database structure.

 @return `nil` if the database structure matches the defined structure, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)check;

/**
 Check the table structure.

 @param table Name of the table to check.
 @param columns Dictionary with column name and data type.

 @return `nil` if structure matches the defined structure, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The columns are matched against the defined structure, so even if the column
 order is the only thing that have been changed the method with return an error.
 */
- (NSError *)checkTable:(NSString *)table withColumns:(NSDictionary *)columns;

/**
 Fetch a result set from the database, without parameters.

 @param sql Query to perform against the database.

 @code
 [self fetch:@"SELECT id, name FROM foo"]
 @endcode

 @return Result from query, or `nil` if nothing is found or an error has occurred.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If `nil` is returned, the error message and code can be retrieved from the error-method.
 */
- (NSArray *)fetch:(NSString *)sql;

/**
 Fetch a result set from the database, with parameters.

 @param sql Query to perform against the database.
 @param params Parameters to bind to the query.

 @code
 [self fetch:@"SELECT name FROM foo WHERE type = ?" withParams:@[@"bar"]]
 @endcode

 @return Result from query, or `nil` if nothing is found or an error has occurred.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If `nil` is returned, the error message and code can be retrieved from the error-method.

 @par
 The first index within the params array will bind against the first question
 mark within the query. The second, to the second question mark, etc.
 */
- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params;

/**
 Fetch row from the database, without parameters.

 @param sql Query to perform against the database.

 @code
 [self fetchRow:@"SELECT name FROM users"]
 @endcode

 @return Result from query, or `nil` if nothing is found or an error has occurred.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If `nil` is returned, the error message and code can be retrieved from the error-method.
 */
- (NSDictionary *)fetchRow:(NSString *)sql;

/**
 Fetch row from the database, with parameters.

 @param sql Query to perform against the database.
 @param params Parameters to bind to the query.

 @code
 [self fetchRow:@"SELECT name FROM user WHERE id = ?" withParams:@[@4]]
 [self fetchRow:@"SELECT name FROM user WHERE id = ? AND type = ?" withParams:@[@4, @"demo"]]
 @endcode

 @return Result from query, or `nil` if nothing is found or an error has occurred.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If `nil` is returned, the error message and code can be retrieved from the error-method.

 @par
 The first index within the params array will bind against the first question
 mark within the query. The second, to the second question mark, etc.
 */
- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params;

/**
 Execute query against database, without parameters.

 @param sql Query to perform against the database.

 @code
 [self execute:@"UPDATE foo SET bar = 'baz'"]
 @endcode

 @return `nil` if query is successful, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The query is successful if no errors occurred, it´s not dependant on affected rows.
 */
- (NSError *)execute:(NSString *)sql;

/**
 Execute query against database, with parameters.

 @param sql Query to perform against the database.
 @param params Parameters to bind to the query.

 @code
 [self execute:@"UPDATE foo SET bar = ? WHERE id = ?" withParams:@[@"baz", @24]];
 @endcode

 @return `nil` if query is successful, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The first index within the params array will bind against the first question
 mark within the query. The second, to the second question mark, etc.

 @par
 The query is successful if no errors occurred, it´s not dependant on affected rows.
 */
- (NSError *)execute:(NSString *)sql withParams:(NSArray *)params;

/**
 Assemble the error object.

 @param description Message for the error.
 @param code Code for the error.

 @return Error object with message and code.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)errorWithDescription:(NSString *)description code:(NSInteger)code;

/**
 Attempt to begin transaction.

 @param type Transaction type.

 @return `nil` if transaction began, otherwith an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)beginTransaction:(RASqliteTransaction)type;

/**
 Attempt to begin a deferred transaction.

 @return `nil` if transaction began, otherwith an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)beginTransaction;

/**
 Attempt to roll back the transaction changes.

 @return `nil` if transaction rolled back, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)rollBack;

/**
 Attempt to commit the transaction changes.

 @return `nil` if transaction commited the changes, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)commit;

/**
 Retrieve last insert id.

 @return Last inserted id, or `nil` if database is empty or an error occurred.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If `nil` is returned, the error message and code can be retrieved from the error-method.
 */
- (NSNumber *)lastInsertId;

@end