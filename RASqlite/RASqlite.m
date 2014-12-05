//
//  RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013-2014 Raatiniemi. All rights reserved.
//

#import "RASqlite.h"

// -- -- Threading

/// Format for the name of the query threads.
static NSString *RASqliteThreadFormat = @"me.raatiniemi.rasqlite.%@";

/// The key used for setting/getting the name for the dispatch queue.
static char *RASqliteKeyQueueName = "me.raatiniemi.rasqlite.queue.name";

// -- -- Exception

/// Exception name for incorrect initialization.
static NSString *RASqliteIcorrectInitializationException = @"Incorrect initialization";

/// Exception name for initialization with an invalid path.
static NSString *RASqliteInvalidPathException = @"Invalid path";

/// Exception name for issues with filesystem permissions.
static NSString *RASqliteFilesystemPermissionException = @"Filesystem permissions";

/// Exception name for detection of nested transactions.
static NSString *RASqliteNestedTransactionException = @"Nested transactions";

// -- -- Import

// Importing categories for Foundation objects that should not be made available
// for the rest of the application. These are specific for RASqlite.
#import "NSError+RASqlite.h"
#import "NSMutableDictionary+RASqlite.h"

/**
 RASqlite is a simple library for working with SQLite databases on iOS and Mac OS X.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqlite () {
@private
	sqlite3 *_database;

	dispatch_queue_t _queue;

	NSString *_path;

	NSUInteger _retryTimeout;
}

/// Stores the path for the database file.
@property (strong, atomic) NSString *path;

/// Number of attempts before the retry timeout is reached.
@property (atomic) NSUInteger retryTimeout;

#pragma mark - Path

/**
 Check the directory path.

 @param path Absolute path to the database file, filename will be stripped.

 @return `YES` if directory is valid (writeable/readable), otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 If the directory do not exists, the method will attempt to create it. It will
 also check that the directory actually is readable and writeable.
 */
- (BOOL)checkPath:(NSString *)path;

#pragma mark - Query

/**
 Bind the parameters to the statement.

 @param columns Parameters to bind to the statement.
 @param statement Statement on which the parameters will be binded.

 @return `YES` if binding is successful, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement;

/**
 Fetch the retrieved columns from the SQL query.

 @param statement Statement from which to retrieve the columns.

 @return Row with the column names and their values.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The dictionary will contain the Foundation representations of the SQLite data types,
 e.g. `SQLITE_INTEGER` will be `NSNumber`, `SQLITE_NULL` will be `NSNull`, etc.
 */
- (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement;

#pragma mark -- Transaction

/**
 Begin specified type of transaction.

 @param type The transaction type to begin.

 @return `YES` if the transaction is started, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)beginTransaction:(RASqliteTransaction)type;

/**
 Begin default (deferred) transaction type.

 @return `YES` if the transaction is started, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)beginTransaction;

/**
 Attempt to roll back the transaction changes.

 @return `YES` if the transaction have been rolled back, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)rollBack;

/**
 Attempt to commit the transaction changes.

 @return `YES` if the transaction have been committed, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)commit;

/**
 Check whether the current database is in transaction.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)inTransaction;

#pragma mark -- Queue

/**
 Execute an internal block on the database specified queue.

 @param block Block to be executed.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (void)queueInternalBlock:(void (^)(void))block;

@end

@implementation RASqlite

@synthesize database = _database;

@synthesize queue = _queue;

@synthesize path = _path;

@synthesize retryTimeout = _retryTimeout;

@synthesize error = _error;

#pragma mark - Initialization

- (id)init
{
	// TODO: Implement support for in memory databases with init as method?
	// Use designated initializator, e.g. from the `init` method run the
	// `initWithPath:`. If the path is @"" or `nil` the database should be
	// initialized as memory database.

	// Use of this method is not allowed, `initWithName:` or `initWithPath:` should be used.
	[NSException raise:RASqliteIcorrectInitializationException
				format:@"Use of the `init` method is not allowed, use `initWithName:` or `initWithPath:` instead."];

	// Return nil, takes care of the return warning.
	return nil;
}

- (instancetype)initWithPath:(NSString *)path
{
	if ( self = [super init] ) {
		// Check if the path is writeable, among other things.
		if( ![self checkPath:path] ) {
			// There is something wrong with the path, raise an exception.
			[NSException raise:RASqliteInvalidPathException
						format:@"The supplied path `%@` can not be used.", path];
		}
		// Assign the database path.
		[self setPath:path];

		// Create the thread for running queries, using the name for the database file.
		NSString *thread = RASqliteSF(RASqliteThreadFormat, [[self path] lastPathComponent]);
		[self setQueue:dispatch_queue_create([thread UTF8String], NULL)];

		// Set the name of the query queue to the container. It will be used to
		// check if the current queue is the query queue.
		dispatch_queue_set_specific([self queue], RASqliteKeyQueueName, (void *)[thread UTF8String], NULL);

		// Set the number of retry attempts before a timeout is triggered.
		[self setRetryTimeout:0];
	}
	return self;
}

- (instancetype)initWithName:(NSString *)name
{
	// Assemble the path for the database file.
	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [self initWithPath:RASqliteSF(@"%@/%@", [directories objectAtIndex:0], name)];
}

#pragma mark - Path

- (BOOL)checkPath:(NSString *)path
{
	// Check that a path actually have been supplied.
	if ( path == nil ) {
		[NSException raise:NSInvalidArgumentException
					format:@"The supplied path can not be `nil`."];
	}

	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *directory = [path stringByDeletingLastPathComponent];

	NSError *error;
	BOOL isValidDirectory = NO;
	do {
		BOOL isDirectory = NO;
		BOOL exists = [manager fileExistsAtPath:directory isDirectory:&isDirectory];

		// If the path do not exists, we need to create it.
		if ( !exists ) {
			// Attempt to create the directory.
			BOOL created = [manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
			if ( !created ) {
				RASqliteLog(RASqliteLogLevelError, @"Unable to create directory `%@` with error: %@", directory, [error localizedDescription]);
				break;
			}
			// The directory have been created, change the directory flag.
			isDirectory = YES;
		}
		// Check if the directory is actually a directory. If it's not a string
		// we need delete the last path component (i.e. filename).
		if ( !isDirectory ) {
			directory = [directory stringByDeletingLastPathComponent];
		} else {
			BOOL readable = [manager isReadableFileAtPath:directory];
			BOOL writeable = [manager isWritableFileAtPath:directory];

			// Check that the directory is both readable and writeable.
			if ( !readable || !writeable ) {
				[NSException raise:RASqliteFilesystemPermissionException
							format:@"The directory `%@` need to be readable and writeable.", directory];
			}
			isValidDirectory = YES;
		}
	} while ( !isValidDirectory );

	return isValidDirectory;
}

#pragma mark - Database

- (void)setDatabase:(sqlite3 *)database
{
	// Protection from rewriting the database pointer mid execution. The pointer
	// have to be resetted before setting a new instance.
	if ( [self database] == nil || database == nil ) {
		_database = database;
	} else {
		// Incase an rewrite have been attempted, this should be logged.
		RASqliteLog(RASqliteLogLevelWarning, @"Attempt to rewrite database pointer.");
	}
}

- (sqlite3 *)database
{
	return _database;
}

- (BOOL)openWithFlags:(int)flags
{
	NSError __block *error;

	[self queueInternalBlock:^{
		// Check if the database already is active, not need to open it.
		sqlite3 *database = [self database];
		if ( !database ) {
			// Attempt to open the database.
			int code = sqlite3_open_v2([[self path] UTF8String], &database, flags, NULL);
			if ( code == SQLITE_OK ) {
				// The database was successfully opened.
				[self setDatabase:database];
				RASqliteLog(RASqliteLogLevelInfo, @"Database `%@` have successfully been opened.", [[self path] lastPathComponent]);
			} else {
				// Something went wrong...
				const char *errmsg = sqlite3_errmsg(database);
				NSString *message = RASqliteSF(@"Unable to open database: %s", errmsg);
				RASqliteLog(RASqliteLogLevelError, @"%@", message);

				error = [NSError code:RASqliteErrorOpen message:message];
				[self setError:error];
			}
		} else {
			// No need to attempt to open the database, it's already open.
			RASqliteLog(RASqliteLogLevelDebug, @"Database is already open.");
		}
	}];

	return error == nil;
}

- (BOOL)open
{
	return [self openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE];
}

- (BOOL)close
{
	NSError __block *error;

	[self queueInternalBlock:^{
		// Check if we have an active database instance, no need to attempt
		// a close if we don't.
		sqlite3 *database = [self database];
		if ( database ) {
			// We have to check whether we have an active transaction. The
			// `sqlite3_close` will close the database even if a transaction
			// lock have been acquired.
			if ( ![self inTransaction] ) {
				BOOL retry;
				int code;

				// Checks of number of attempts, will prevent infinite loops.
				NSInteger attempt = 0;

				// Repeat the close process until the database is closed, an error
				// occurres, or the retry attempts have been depleted.
				do {
					// Reset the retry control and attempt to close the database.
					retry = NO;
					code = sqlite3_close(database);

					// Check whether the database is busy or locked.
					// By default, sqlite3 do not check if a transaction is
					// active this has to be manually checked.
					if ( code == SQLITE_BUSY || code == SQLITE_LOCKED ) {
						// Since every query against the same database is executed
						// on the same queue it is highly unlikely that the database
						// would be busy or locked, but better to be safe.
						RASqliteLog(RASqliteLogLevelInfo, @"Database is busy/locked, retrying to close.");
						retry = YES;

						// Check if the retry timeout have been reached.
						if ( attempt++ > [self retryTimeout] ) {
							RASqliteLog(RASqliteLogLevelInfo, @"Retry timeout have been reached, unable to close database.");
							retry = NO;
						}
					} else if ( code != SQLITE_OK ) {
						// Something went wrong...
						const char *errmsg = sqlite3_errmsg(database);
						NSString *message = RASqliteSF(@"Unable to close database: %s", errmsg);
						RASqliteLog(RASqliteLogLevelError, @"%@", message);

						error = [NSError code:RASqliteErrorClose message:message];
						[self setError:error];
					} else {
						[self setDatabase:nil];
						RASqliteLog(RASqliteLogLevelInfo, @"Database `%@` have successfully been closed.", [[self path] lastPathComponent]);
					}
				} while (retry);
			}
		} else {
			// No need to close, it is already closed.
			RASqliteLog(RASqliteLogLevelDebug, @"Database is already closed.");
		}
	}];

	return error == nil;
}

#pragma mark - Query

- (BOOL)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement
{
	NSError *error;

	// Get the pointer for the method, performance improvement.
	SEL selector = @selector(isKindOfClass:);

	typedef BOOL (*isClass) (id, SEL, Class);
	isClass isKindOfClass = (isClass)[self methodForSelector:selector];

	int code = SQLITE_OK;
	unsigned int index = 1;
	for ( id column in columns ) {
		if ( isKindOfClass(column, selector, [NSString class]) ) {
			// Sqlite do not seem to fully support UTF-16 yet, so no need to
			// implement support for the `sqlite3_bind_text16` functionality.
			code = sqlite3_bind_text(*statement, index, [column UTF8String], -1, SQLITE_TRANSIENT);
		} else if ( isKindOfClass(column, selector, [NSNumber class]) ) {
			const char *type = [column objCType];
			if ( strcmp(type, @encode(double)) == 0 || strcmp(type, @encode(float)) == 0 ) {
				// Both double and float should be binded as double.
				code = sqlite3_bind_double(*statement, index, [column doubleValue]);
			} else if ( strcmp(type, @encode(long)) == 0 || strcmp(type, @encode(long long)) == 0 ) {
				code = sqlite3_bind_int64(*statement, index, [column longLongValue]);
			} else {
				// Every data type that is not specified should be binded as int.
				code = sqlite3_bind_int(*statement, index, [column intValue]);
			}
		} else if ( isKindOfClass(column, selector, [NSNull class]) ) {
			code = sqlite3_bind_null(*statement, index);
		} else {
			unsigned int length = (unsigned int)[column length];
			code = sqlite3_bind_blob(*statement, index, [column bytes], length, SQLITE_TRANSIENT);
		}

		// Check if the binding of the column was successful.
		if ( code != SQLITE_OK ) {
			NSString *message = RASqliteSF(@"Unable to bind type `%@`.", [column class]);
			RASqliteLog(RASqliteLogLevelError, @"%@", message);

			error = [NSError code:RASqliteErrorBind message:message];
			[self setError:error];
			break;
		}
		index++;
	}

	return error == nil;
}

- (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement
{
	unsigned int count = sqlite3_column_count(*statement);
	NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:count];

	const char *name;
	NSString *column;

	unsigned int index;
	int type;
	// Loop through the columns.
	for ( index = 0; index < count; index++ ) {
		name = sqlite3_column_name(*statement, index);
		column = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

		// Check which column type the current index is and bind the column value.
		type = sqlite3_column_type(*statement, index);
		switch ( type ) {
			case SQLITE_INTEGER: {
				// TODO: Test on 32-bit machine.
				long long int value = sqlite3_column_int64(*statement, index);
				[row setColumn:column withObject:[NSNumber numberWithLongLong:value]];
				break;
			}
			case SQLITE_FLOAT: {
				double value = sqlite3_column_double(*statement, index);
				[row setColumn:column withObject:[NSNumber numberWithDouble:value]];
				break;
			}
			case SQLITE_BLOB: {
				// Retrieve the value and the number of bytes for the blob column.
				const void *value = (void *)sqlite3_column_blob(*statement, index);
				NSUInteger bytes = sqlite3_column_bytes(*statement, index);
				[row setColumn:column withObject:[NSData dataWithBytes:value length:bytes]];
				break;
			}
			case SQLITE_NULL: {
				[row setColumn:column withObject:[NSNull null]];
				break;
			}
			case SQLITE_TEXT:
			default: {
				// Sqlite do not seem to fully support UTF-16 yet, so no need to
				// implement support for the `sqlite3_column_text16` functionality.
				const char *value = (const char *)sqlite3_column_text(*statement, index);
				[row setColumn:column withObject:[NSString stringWithCString:value encoding:NSUTF8StringEncoding]];
				break;
			}
		}
	}

	return row;
}

#pragma mark -- Fetch

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params
{
	NSMutableArray __block *results;

	[self queueInternalBlock:^{
		// If we don't have a valid database instance we have attempt to open it.
		if ( [self database] || [self open] ) {
			NSError __block *error;

			sqlite3_stmt *statement;
			int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

			if ( code == SQLITE_OK ) {
				// If we have parameters, we need to bind them to the statement.
				if ( !params || [self bindColumns:params toStatement:&statement] ) {
					// Get the pointer for the method, performance improvement.
					SEL selector = @selector(fetchColumns:);

					typedef NSDictionary* (*fetch) (id, SEL, sqlite3_stmt**);
					fetch fetchColumns = (fetch)[self methodForSelector:selector];

					NSDictionary *row;
					results = [[NSMutableArray alloc] init];

					// Looping through the results, until an error occurres or
					// the query is done.
					do {
						code = sqlite3_step(statement);

						if ( code == SQLITE_ROW ) {
							row = fetchColumns(self, selector, &statement);
							[results addObject:row];
						} else if ( code == SQLITE_DONE ) {
							// Results have been fetch, leave the loop.
							break;
						} else {
							// Something has gone wrong, leave the loop.
							const char *errmsg = sqlite3_errmsg([self database]);
							NSString *message = RASqliteSF(@"Unable to fetch row: %s", errmsg);
							RASqliteLog(RASqliteLogLevelError, @"%@", message);

							error = [NSError code:RASqliteErrorQuery message:message];
							[self setError:error];

							// Since an error has occurred we need to reset the results.
							results = nil;
						}
					} while ( !error );
				}
			} else {
				// Something went wrong...
				const char *errmsg = sqlite3_errmsg([self database]);
				NSString *message = RASqliteSF(@"Failed to prepare statement `%@`: %s", sql, errmsg);
				RASqliteLog(RASqliteLogLevelError, @"%@", message);

				error = [NSError code:RASqliteErrorQuery message:message];
				[self setError:error];
			}
			sqlite3_finalize(statement);
		}
	}];

	return results;
}

- (NSArray *)fetch:(NSString *)sql withParam:(id)param
{
	return [self fetch:sql withParams:@[param]];
}

- (NSArray *)fetch:(NSString *)sql
{
	return [self fetch:sql withParams:nil];
}

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params
{
	NSDictionary __block *row;

	[self queueInternalBlock:^{
		// If we don't have a valid database instance we have attempt to open it.
		if ( [self database] || [self open] ) {
			NSError *error;

			sqlite3_stmt *statement;
			int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

			if ( code == SQLITE_OK ) {
				// If we have parameters, we need to bind them to the statement.
				if ( !params || [self bindColumns:params toStatement:&statement] ) {
					code = sqlite3_step(statement);
					if ( code == SQLITE_ROW ) {
						row = [self fetchColumns:&statement];

						// If the error variable have been populated, something
						// has gone wrong and we need to reset the row variable.
						if ( error || [row count] == 0 ) {
							row = nil;
						}
					} else if ( code == SQLITE_DONE ) {
						RASqliteLog(RASqliteLogLevelDebug, @"No rows were found with query: %@", sql);
					} else {
						// Something went wrong...
						const char *errmsg = sqlite3_errmsg([self database]);
						NSString *message = RASqliteSF(@"Failed to retrieve result: %s", errmsg);
						RASqliteLog(RASqliteLogLevelError, @"%@", message);

						error = [NSError code:RASqliteErrorQuery message:message];
						[self setError:error];
					}
				}
			} else {
				// Something went wrong...
				const char *errmsg = sqlite3_errmsg([self database]);
				NSString *message = RASqliteSF(@"Failed to prepare statement `%@`: %s", sql, errmsg);
				RASqliteLog(RASqliteLogLevelError, @"%@", message);

				error = [NSError code:RASqliteErrorQuery message:message];
				[self setError:error];
			}
			sqlite3_finalize(statement);
		}
	}];

	return row;
}

- (NSDictionary *)fetchRow:(NSString *)sql withParam:(id)param
{
	return [self fetchRow:sql withParams:@[param]];
}

- (NSDictionary *)fetchRow:(NSString *)sql
{
	return [self fetchRow:sql withParams:nil];
}

#pragma mark -- Update

- (BOOL)execute:(NSString *)sql withParams:(NSArray *)params
{
	BOOL __block success = NO;

	[self queueInternalBlock:^{
		// If we don't have a valid database instance we have attempt to open it.
		if ( [self database] || [self open] ) {
			NSError *error;

			sqlite3_stmt *statement;
			int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

			if ( code == SQLITE_OK ) {
				// If we have parameters, we need to bind them to the statement.
				if ( !params || [self bindColumns:params toStatement:&statement] ) {
					code = sqlite3_step(statement);
					if ( code == SQLITE_DONE ) {
						// Statement have been successfully executed.
						success = YES;
					} else {
						// Something went wrong...
						const char *errmsg = sqlite3_errmsg([self database]);
						NSString *message = RASqliteSF(@"Failed to execute query: %s", errmsg);
						RASqliteLog(RASqliteLogLevelError, @"%@", message);

						error = [NSError code:RASqliteErrorQuery message:message];
						[self setError:error];
					}
				}
			} else {
				// Something went wrong...
				const char *errmsg = sqlite3_errmsg([self database]);
				NSString *message = RASqliteSF(@"Failed to prepare statement `%@`: %s", sql, errmsg);
				RASqliteLog(RASqliteLogLevelError, @"%@", message);

				error = [NSError code:RASqliteErrorQuery message:message];
				[self setError:error];
			}
			sqlite3_finalize(statement);
		}
	}];

	return success;
}

- (BOOL)execute:(NSString *)sql withParam:(id)param
{
	return [self execute:sql withParams:@[param]];
}

- (BOOL)execute:(NSString *)sql
{
	return [self execute:sql withParams:nil];
}

#pragma mark -- Transaction

- (BOOL)beginTransaction:(RASqliteTransaction)type
{
	NSError __block *error = [self error];
	if ( !error ) {
		[self queueInternalBlock:^{
			// If we don't have a valid database instance we have attempt to open it.
			[self database] || [self open];

			const char *sql;
			switch (type) {
				case RASqliteTransactionExclusive:
					sql = "BEGIN EXCLUSIVE TRANSACTION";
					break;
				case RASqliteTransactionImmediate:
					sql = "BEGIN IMMEDIATE TRANSACTION";
					break;
				case RASqliteTransactionDeferred:
				default:
					sql = "BEGIN DEFERRED TRANSACTION";
					break;
			}

			char *errmsg;
			int code = sqlite3_exec([self database], sql, 0, 0, &errmsg);
			if ( code != SQLITE_OK ) {
				NSString *message = [NSString stringWithCString:errmsg encoding:NSUTF8StringEncoding];
				RASqliteLog(RASqliteLogLevelError, @"Unable to begin transaction: %@", message);
				error = [NSError code:RASqliteErrorTransaction message:message];
			}
		}];

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
}

- (BOOL)beginTransaction
{
	return [self beginTransaction:RASqliteTransactionDeferred];
}

- (BOOL)rollBack
{
	NSError __block *error = [self error];
	if ( !error ) {
		[self queueInternalBlock:^{
			char *errmsg;
			int code = sqlite3_exec([self database], "ROLLBACK TRANSACTION", 0, 0, &errmsg);
			if ( code != SQLITE_OK ) {
				NSString *message = [NSString stringWithCString:errmsg encoding:NSUTF8StringEncoding];
				RASqliteLog(RASqliteLogLevelError, @"Unable to rollback transaction: %@", message);
				error = [NSError code:RASqliteErrorTransaction message:message];
			}
		}];

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
}

- (BOOL)commit
{
	NSError __block *error = [self error];
	if ( !error ) {
		[self queueInternalBlock:^{
			char *errmsg;
			int code = sqlite3_exec([self database], "COMMIT TRANSACTION", 0, 0, &errmsg);
			if ( code != SQLITE_OK ) {
				NSString *message = [NSString stringWithCString:errmsg encoding:NSUTF8StringEncoding];
				RASqliteLog(RASqliteLogLevelError, @"Unable to commit transaction: %@", message);
				error = [NSError code:RASqliteErrorTransaction message:message];
			}
		}];

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
}

- (BOOL)inTransaction
{
	BOOL __block inTransaction = NO;
	[self queueInternalBlock:^{
		// Using the `sqlite3_get_autocommit` to check whether the database is
		// currently in a transaction.
		// http://sqlite.org/c3ref/get_autocommit.html
		//
		// If we do not have an active database instance we can not decide
		// whether the database is in an transaction. This scenario should only
		// occur if we are accessing the database from a secondary source.
		inTransaction = [self database] && sqlite3_get_autocommit([self database]) == 0;
	}];

	return inTransaction;
}

#pragma mark -- Queue

- (void)queueInternalBlock:(void (^)(void))block
{
	// Attempt to retrieve the name from the current dispatch queue, and
	// compare it against the name of the query dispatch queue. If the name
	// matches we're on the correct queue.
	void *name = dispatch_get_specific(RASqliteKeyQueueName);
	if ( name == dispatch_queue_get_specific([self queue], RASqliteKeyQueueName) ) {
		block();
	} else {
		dispatch_sync([self queue], ^{
			block();
		});
	}
}

- (void)queueWithBlock:(void (^)(RASqlite *db))block
{
	[self queueInternalBlock:^{
		block(self);
	}];
}

- (void)queueTransaction:(RASqliteTransaction)transaction withBlock:(void (^)(RASqlite *db, BOOL *commit))block
{
	[self queueWithBlock:^(RASqlite *db) {
		// Check if we're already within a transaction. There are two
		// implementation alternatives regarding `inTransaction`. Either, an
		// exception is raised to prevent nested transactions or the inner
		// transaction omits the begin transaction. However, the second
		// alternatives poses some difficulties when it comes to the
		// commit/rollback. Therefor, the first alternative is implemented.
		if ( [self inTransaction] ) {
			[NSException raise:RASqliteNestedTransactionException
						format:@"A nested transaction have been detected, this is not allowed."];
		}
		[self beginTransaction:transaction];

		BOOL commit = NO;
		block(db, &commit);

		if ( commit ) {
			[self commit];
		} else {
			[self rollBack];
		}
	}];
}

- (void)queueTransactionWithBlock:(void (^)(RASqlite *db, BOOL *commit))block
{
	[self queueTransaction:RASqliteTransactionDeferred withBlock:block];
}

@end
