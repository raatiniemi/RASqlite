//
//  RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013-2014 Raatiniemi. All rights reserved.
//

#import "RASqlite.h"

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

	NSInteger _retryTimeout;

	BOOL _inTransaction;
}

/// Stores the path for the database file.
@property (strong, atomic) NSString *path;

/// Number of attempts before the retry timeout is reached.
@property (atomic) NSInteger retryTimeout;

/// Check for preventing transaction within transactions.
@property (atomic) BOOL inTransaction;

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

 @return `nil` if binding is successful, otherwise an error object.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (NSError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement;

/**
 Fetch the retrieved columns from the SQL query.

 @param statement Statement from which to retrieve the columns.
 @param error If an error occurred, variable will be populated (pass-by-reference).

 @return Row with the column names and their values.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The dictionary will contain the Foundation representations of the SQLite data types,
 e.g. `SQLITE_INTEGER` will be `NSNumber`, `SQLITE_NULL` will be `NSNull`, etc.
 */
- (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement withError:(NSError **)error;

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

@end

@implementation RASqlite

@synthesize database = _database;

@synthesize queue = _queue;

@synthesize path = _path;

@synthesize retryTimeout = _retryTimeout;

@synthesize inTransaction = _inTransaction;

@synthesize error = _error;

#pragma mark - Initialization

- (id)init
{
	// TODO: Implement support for in memory databases with init as method?

	// Use of this method is not allowed, `initWithName:` or `initWithPath:` should be used.
	[NSException raise:@"Incorrect initialization"
				format:@"Use of the `init` method is not allowed, use `initWithName:` or `initWithPath:` instead."];

	// Return nil, takes care of the return warning.
	return nil;
}

- (instancetype)initWithPath:(NSString *)path
{
	if ( self = [super init] ) {
		// Assign the database path.
		[self setPath:path];

		// Check if the path is writeable, among other things.
		if( ![self checkPath:[self path]] ) {
			// There is something wrong with the path, raise an exception.
			[NSException raise:@"Invalid path"
						format:@"The supplied path `%@` can not be used.", [self path]];
		}

		// Create the thread for running queries, using the name for the database file.
		NSString *thread = [NSString stringWithFormat:kRASqliteThreadFormat, [[self path] lastPathComponent]];
		[self setQueue:dispatch_queue_create([thread UTF8String], NULL)];

		// Set the name of the query queue to the container. It will be used to
		// check if the current queue is the query queue.
		dispatch_queue_set_specific([self queue], kRASqliteKeyQueueName, (void *)[thread UTF8String], NULL);

		// Set the number of retry attempts before a timeout is triggered.
		[self setRetryTimeout:0];

		// Set the default value for the `inTransaction`.
		[self setInTransaction:NO];
	}
	return self;
}

- (instancetype)initWithName:(NSString *)name
{
	// Assemble the path for the database file.
	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [self initWithPath:[NSString stringWithFormat:@"%@/%@", [directories objectAtIndex:0], name]];
}

#pragma mark - Path

- (BOOL)checkPath:(NSString *)path
{
	// Check that a path actually have been supplied.
	if ( path == nil ) {
		[NSException raise:NSInvalidArgumentException
					format:@"The supplied path can not be `nil`. "];
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
				[NSException raise:@"Filesystem permissions"
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

- (NSError *)openWithFlags:(int)flags
{
	NSError __block *error = [self error];
	if ( !error ) {
		void (^block)(void) = ^(void) {
			// Check if the database already is active, not need to open it.
			sqlite3 *database = [self database];
			if ( !database ) {
				int code = sqlite3_open_v2([[self path] UTF8String], &database, flags, NULL);
				if ( code == SQLITE_OK ) {
					// The database was successfully opened.
					[self setDatabase:database];
					RASqliteLog(RASqliteLogLevelInfo, @"Database `%@` have successfully been opened.", [[self path] lastPathComponent]);
				} else {
					// Something went wrong...
					NSString *message = [NSString stringWithFormat:@"Unable to open database, received code `%i`.", code];
					RASqliteLog(RASqliteLogLevelError, @"%@", message);
					error = [NSError code:RASqliteErrorOpen message:message];
				}
			} else {
				// No need to attempt to open the database, it's already open.
				RASqliteLog(RASqliteLogLevelDebug, @"Database is already open.");
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		char *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error;
}

- (NSError *)open
{
	return [self openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE];
}

- (NSError *)close
{
	NSError __block *error = [self error];
	if ( !error ) {
		void (^block)(void) = ^(void) {
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
							NSString *message = [NSString stringWithFormat:@"Unable to close database, received code `%i`.", code];
							RASqliteLog(RASqliteLogLevelError, @"%@", message);
							error = [NSError code:RASqliteErrorClose message:message];
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
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error;
}

#pragma mark - Table

- (BOOL)check
{
	// Keep track if whether the structure for the table is valid. The default
	// value have to be `YES`, otherwise we risk of deleting the table when
	// something is wrong with the database instance.
	BOOL __block valid = YES;
	NSError *error = [self error];

	// Check whether we have a valid database instance.
	// Attempt to open it if no errors have occurred yet.
	if ( ![self database] && !error ) {
		error = [self open];
	}

	// If an error has occurred we should not attempt to perform the action.
	if ( !error ) {
		void (^block)(void) = ^(void) {
			NSDictionary *tables = [self structure];
			if ( tables ) {
				// Get the pointer for the method, performance improvement.
				SEL selector = @selector(checkTable:withColumns:);

				typedef BOOL (*check) (id, SEL, NSString*, NSDictionary*);
				check checkTable = (check)[self methodForSelector:selector];

				for ( NSString *table in tables ) {
					if ( !checkTable(self, selector, table, [tables objectForKey:table]) ) {
						valid = NO;
						break;
					}
				}
			} else {
				// Raise an exception, no structure have been supplied.
				[NSException raise:@"Check database"
							format:@"Unable to check database structure, none has been supplied."];
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}
	}

	return valid;
}

- (BOOL)checkTable:(NSString *)table withColumns:(NSArray *)columns
{
	if ( !table ) {
		// Raise an exception, no valid table name.
		[NSException raise:@"Check table"
					format:@"Unable to check table without valid name."];
	}

	if ( !columns ) {
		// Raise an exception, no defined columns.
		[NSException raise:@"Check table"
					format:@"Unable to check table without defined columns."];
	}

	// Keeps track on whether the structure for the table is valid. The default
	// value have to be `YES`, otherwise we risk of deleting the table when
	// something is wrong with the database instance.
	BOOL __block valid = YES;
	NSError *error = [self error];

	// Check whether we have a valid database instance.
	// Attempt to open it if no errors have occurred yet.
	if ( ![self database] && !error ) {
		error = [self open];
	}

	// If an error has occurred we should not attempt to perform the action.
	if ( !error ) {
		void (^block)(void) = ^(void) {
			// Check whether the defined columns and the table columns match.
			NSArray *tColumns = [self fetch:[NSString stringWithFormat:@"PRAGMA table_info(%@)", table]];
			if ( [tColumns count] > 0 ) {
				if ( [tColumns count] == [columns count] ) {
					unsigned int index = 0;
					for ( RASqliteColumn *column in columns ) {
						// The column have to be of type `RASqliteColumn`.
						if ( ![column isKindOfClass:[RASqliteColumn class]] ) {
							[NSException raise:NSInvalidArgumentException
										format:@"Column defined for table `%@` at index `%i` is not of type `RASqliteColumn.", table, index];
						}

						// Retrieve the column definition from the table.
						NSDictionary *tColumn = [tColumns objectAtIndex:index];

						// Check that the column name matches.
						if ( ![[tColumn getColumn:@"name"] isEqualToString:[column name]] ) {
							RASqliteLog(RASqliteLogLevelDebug, @"Column name at index `%i` do not match column given for structure `%@`.", index, table);
							valid = NO;
							break;
						}

						// Check that the column type matches.
						if ( ![[tColumn getColumn:@"type"] isEqualToString:[column type]] ) {
							RASqliteLog(RASqliteLogLevelDebug, @"Column type at index `%i` do not match column given for structure `%@`.", index, table);
							valid = NO;
							break;
						}

						// Check that whether the column matches the primary key setting.
						if ( [column isPrimaryKey] != [[tColumn getColumn:@"pk"] boolValue] ) {
							RASqliteLog(RASqliteLogLevelDebug, @"Column primary key option at index `%i` do not match column given for structure `%@`.", index, table);
							valid = NO;
							break;
						}

						// Check that whether the column matches the nullable setting.
						if ( [column isNullable] == [[tColumn getColumn:@"notnull"] boolValue] ) {
							RASqliteLog(RASqliteLogLevelDebug, @"Column nullable option at index `%i` do not match column given for structure `%@`.", index, table);
							valid = NO;
							break;
						}

						// TODO: Check the default value, `dflt_value` from tColumn.
						// TODO: Check for unique columns.
						// TODO: Check for autoincremental.

						index++;
					}
				} else {
					RASqliteLog(RASqliteLogLevelDebug, @"Number of specified columns for table `%@` do not matched the defined table count.", table);
					valid = NO;
				}
			} else {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` do not exist with any structure within the database.", table);
				valid = NO;
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}
	}

	return valid;
}

- (BOOL)create
{
	// Keeps track on whether the structure was created.
	BOOL __block created = NO;
	NSError *error = [self error];

	// Check whether we have a valid database instance.
	// Attempt to open it if no errors have occurred yet.
	if ( ![self database] && !error ) {
		error = [self open];
	}

	// If an error has occurred we should not attempt to perform the action.
	if ( !error ) {
		void (^block)(void) = ^(void) {
			NSDictionary *tables = [self structure];
			if ( tables ) {
				// Get the pointer for the method, performance improvement.
				SEL selector = @selector(createTable:withColumns:);

				typedef BOOL (*create) (id, SEL, NSString*, NSDictionary*);
				create createTable = (create)[self methodForSelector:selector];

				// Change the created check before going in to the create loop.
				created = YES;

				// Loops through each of the tables and attempt to create their structure.
				for ( NSString *table in tables ) {
					if ( !createTable(self, selector, table, [tables objectForKey:table]) ) {
						created = NO;
						break;
					}
				}
			} else {
				// Raise an exception, no structure have been supplied.
				[NSException raise:@"Create database"
							format:@"Unable to create database structure, none has been supplied."];
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}
	}

	return created;
}

- (BOOL)createTable:(NSString *)table withColumns:(NSDictionary *)columns
{
	if ( !table ) {
		// Raise an exception, no valid table name.
		[NSException raise:@"Create table"
					format:@"Unable to create table without valid name."];
	}

	if ( !columns ) {
		// Raise an exception, no defined columns.
		[NSException raise:@"Create table"
					format:@"Unable to create table without defined columns."];
	}

	// Keeps track on whether the table was created.
	BOOL __block created = NO;
	NSError *error = [self error];

	// Check whether we have a valid database instance.
	// Attempt to open it if no errors have occurred yet.
	if ( ![self database] && !error ) {
		error = [self open];
	}

	// If an error has occurred we should not attempt to perform the action.
	if ( !error ) {
		void (^block)(void) = ^(void) {
			// The create query will be constructed with a list of items, each
			// item represent their column name, data type, constraints, etc.
			NSMutableArray *list = [[NSMutableArray alloc] init];
			NSMutableString *item;

			// Assemble the columns and data types for the structure.
			for ( RASqliteColumn *column in columns ) {
				// The column have to be of type `RASqliteColumn`.
				if ( ![column isKindOfClass:[RASqliteColumn class]] ) {
					[NSException raise:NSInvalidArgumentException
								format:@"Column defined for table `%@` is not of type `RASqliteColumn.", table];
				}

				// Start with building the item with the column name and type.
				item = [[NSMutableString alloc] init];
				[item appendFormat:@"%@ %@", [column name], [column type]];

				// Check if the column should be unique.
				if ( [column isUnique] ) {
					[item appendString:@" UNIQUE"];
				}

				// Handle if the column should be nullable or not.
				if ( ![column isNullable] ) {
					[item appendString:@" NOT"];
				}
				[item appendString:@" NULL"];

				// Check if the column should be a primary key.
				if ( [column isPrimaryKey] ) {
					[item appendString:@" PRIMARY KEY"];

					// Column have to be of type `integer` to use `autoincremental`.
					if ( [column isAutoIncrement] && RASqliteInteger == [column numericType] ) {
						[item appendString:@" AUTOINCREMENT"];
					}
				} else {
					// If the column have a default value available, use it.
					// Have to check for nil since default value can be @0.
					if ( [column defaultValue] != nil ) {
						[item appendFormat:@" DEFAULT `%@`", [column defaultValue]];
					}
				}

				// Add the item to the list of columns.
				[list addObject:item];
			}
			// Build the actual sql query for creating the table.
			NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)", table, [list componentsJoinedByString:@","]];
			RASqliteLog(RASqliteLogLevelDebug, @"Create query: %@", sql);

			// Attempt to create the database table.
			created = [self execute:sql];
			if ( created ) {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` have been created.", table);
			} else {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` have not been created.", table);
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}
	}

	return created;
}

- (BOOL)deleteTable:(NSString *)table
{
	if ( !table ) {
		// Raise an exception, no valid table name.
		[NSException raise:@"Remove table"
					format:@"Unable to remove table without valid name."];
	}

	// Keeps track on whether the table was created.
	BOOL __block removed = NO;
	NSError *error = [self error];

	// Check whether we have a valid database instance.
	// Attempt to open it if no errors have occurred yet.
	if ( ![self database] && !error ) {
		error = [self open];
	}

	// If an error has occurred we should not attempt to perform the action.
	if ( !error ) {
		void (^block)(void) = ^(void) {
			// Attempt to remove the database table.
			removed = [self execute:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", table]];
			if ( removed ) {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` have been removed.", table);
			} else {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` have not been removed.", table);
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}
	}

	return removed;
}

#pragma mark - Query

- (NSError *)bindColumns:(NSArray *)columns toStatement:(sqlite3_stmt **)statement
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

		// Check if an error has occurred.
		if ( !error && code != SQLITE_OK ) {
			NSString *message = [NSString stringWithFormat:@"Unable to bind type `%@`.", [column class]];
			RASqliteLog(RASqliteLogLevelError, @"%@", message);
			error = [NSError code:RASqliteErrorBind message:message];
		}

		if ( error ) {
			break;
		}
		index++;
	}

	return error;
}

- (NSDictionary *)fetchColumns:(sqlite3_stmt **)statement withError:(NSError **)error
{
	unsigned int count = sqlite3_column_count(*statement);
	NSMutableDictionary *row = [[NSMutableDictionary alloc] initWithCapacity:count];

	const char *name;
	NSString *column;

	unsigned int index;
	int type;
	// Loop through the columns, or until an error is encountered.
	for ( index = 0; !*error && index < count; index++ ) {
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

	// If the error variable have been populated, something has gone wrong and
	// we need to reset the row variable.
	if ( *error ) {
		row = nil;
	}

	return row;
}

#pragma mark -- Fetch

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params
{
	NSError __block *error = [self error];
	NSMutableArray __block *results;

	if ( !error ) {
		void (^block)(void) = ^(void) {
			// If database is not open, attempt to open it.
			if ( ![self database] ) {
				error = [self open];
			}

			// If an error already have occurred, we should not attempt to execute query.
			if ( !error ) {
				sqlite3_stmt *statement;
				int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

				if ( code == SQLITE_OK ) {
					if ( params ) {
						// If we have parameters, we need to bind them to the statement.
						error = [self bindColumns:params toStatement:&statement];
					}

					if ( !error ) {
						// Get the pointer for the method, performance improvement.
						SEL selector = @selector(fetchColumns:withError:);

						typedef NSDictionary* (*fetch) (id, SEL, sqlite3_stmt**, NSError **);
						fetch fetchColumns = (fetch)[self methodForSelector:selector];

						NSDictionary *row;
						results = [[NSMutableArray alloc] init];

						// Looping through the results, until an error occurres or
						// the query is done.
						do {
							code = sqlite3_step(statement);

							if ( code == SQLITE_ROW ) {
								row = fetchColumns(self, selector, &statement, &error);
								[results addObject:row];
							} else if ( code == SQLITE_DONE ) {
								// Results have been fetch, leave the loop.
								break;
							} else {
								// Something has gone wrong, leave the loop.
								NSString *message = [NSString stringWithFormat:@"Unable to fetch row, received code `%i`.", code];
								RASqliteLog(RASqliteLogLevelError, @"%@", message);
								error = [NSError code:RASqliteErrorQuery message:message];
							}
						} while ( !error );
					}

					// If the error variable have been populated, something
					// has gone wrong and we need to reset the results variable.
					if ( error ) {
						results = nil;
					}
				} else {
					// Something went wrong...
					NSString *message = [NSString stringWithFormat:@"Failed to prepare statement `%@`, received code `%i`.", sql, code];
					RASqliteLog(RASqliteLogLevelError, @"%@", message);
					error = [NSError code:RASqliteErrorQuery message:message];
				}
				sqlite3_finalize(statement);
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

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
	NSError __block *error = [self error];
	NSDictionary __block *row;

	if ( !error ) {
		void (^block)(void) = ^(void) {
			// If database is not open, attempt to open it.
			if ( ![self database] ) {
				error = [self open];
			}

			// If an error already have occurred, we should not attempt to execute query.
			if ( !error ) {
				sqlite3_stmt *statement;
				int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

				if ( code == SQLITE_OK ) {
					if ( params ) {
						// If we have parameters, we need to bind them to the statement.
						error = [self bindColumns:params toStatement:&statement];
					}

					if ( !error ) {
						code = sqlite3_step(statement);
						if ( code == SQLITE_ROW ) {
							row = [self fetchColumns:&statement withError:&error];

							// If the error variable have been populated, something
							// has gone wrong and we need to reset the row variable.
							if ( error || [row count] == 0 ) {
								row = nil;
							}
						} else if ( code == SQLITE_DONE ) {
							RASqliteLog(RASqliteLogLevelDebug, @"No rows were found with query: %@", sql);
						} else {
							NSString *message = [NSString stringWithFormat:@"Failed to retrieve result, received code: `%i`", code];
							RASqliteLog(RASqliteLogLevelError, @"%@", message);
							error = [NSError code:RASqliteErrorQuery message:message];
						}
					}
				} else {
					NSString *message = [NSString stringWithFormat:@"Failed to prepare statement `%@`, received code `%i`.", sql, code];
					RASqliteLog(RASqliteLogLevelError, @"%@", message);
					error = [NSError code:RASqliteErrorQuery message:message];
				}
				sqlite3_finalize(statement);
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

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
	NSError __block *error = [self error];

	if ( !error ) {
		void (^block)(void) = ^(void) {
			// If database is not open, attempt to open it.
			if ( ![self database] ) {
				error = [self open];
			}

			// If an error already have occurred, we should not attempt to execute query.
			if ( !error ) {
				sqlite3_stmt *statement;
				int code = sqlite3_prepare_v2([self database], [sql UTF8String], -1, &statement, NULL);

				if ( code == SQLITE_OK ) {
					if ( params ) {
						// If we have parameters, we need to bind them to the statement.
						error = [self bindColumns:params toStatement:&statement];
					}

					if ( !error ) {
						code = sqlite3_step(statement);
						if ( code != SQLITE_DONE ) {
							NSString *message = [NSString stringWithFormat:@"Failed to execute query, received code: `%i`", code];
							RASqliteLog(RASqliteLogLevelError, @"%@", message);
							error = [NSError code:RASqliteErrorQuery message:message];
						}
					}
				} else {
					NSString *message = [NSString stringWithFormat:@"Failed to prepare statement `%@`, recived code `%i`.", sql, code];
					RASqliteLog(RASqliteLogLevelError, @"%@", message);
					error = [NSError code:RASqliteErrorQuery message:message];
				}
				sqlite3_finalize(statement);
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
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
		void (^block)(void) = ^(void) {
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
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}

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
		void (^block)(void) = ^(void) {
			char *errmsg;
			int code = sqlite3_exec([self database], "ROLLBACK TRANSACTION", 0, 0, &errmsg);
			if ( code != SQLITE_OK ) {
				NSString *message = [NSString stringWithCString:errmsg encoding:NSUTF8StringEncoding];
				RASqliteLog(RASqliteLogLevelError, @"Unable to rollback transaction: %@", message);
				error = [NSError code:RASqliteErrorTransaction message:message];
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}

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
		void (^block)(void) = ^(void) {
			char *errmsg;
			int code = sqlite3_exec([self database], "COMMIT TRANSACTION", 0, 0, &errmsg);
			if ( code != SQLITE_OK ) {
				NSString *message = [NSString stringWithCString:errmsg encoding:NSUTF8StringEncoding];
				RASqliteLog(RASqliteLogLevelError, @"Unable to commit transaction: %@", message);
				error = [NSError code:RASqliteErrorTransaction message:message];
			}
		};

		// Attempt to retrieve the name from the current dispatch queue, and
		// compare it against the name of the query dispatch queue. If the name
		// matches we're on the correct queue.
		void *name = dispatch_get_specific(kRASqliteKeyQueueName);
		if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
			block();
		} else {
			dispatch_sync([self queue], block);
		}

		// If an error occurred performing the query set the error. However,
		// do not override the existing error, if it exists.
		if ( ![self error] && error ) {
			[self setError:error];
		}
	}

	return error == nil;
}

#pragma mark -- Queue

- (void)queueWithBlock:(void (^)(RASqlite *db))block
{
	// Attempt to retrieve the name from the current dispatch queue, and
	// compare it against the name of the query dispatch queue. If the name
	// matches we're on the correct queue.
	void *name = dispatch_get_specific(kRASqliteKeyQueueName);
	if ( name == dispatch_queue_get_specific([self queue], kRASqliteKeyQueueName) ) {
		block(self);
	} else {
		dispatch_sync([self queue], ^{
			block(self);
		});
	}
}

- (void)queueTransaction:(RASqliteTransaction)transaction withBlock:(BOOL (^)(RASqlite *))block
{
	[self queueWithBlock:^(RASqlite *db) {
		// Check if we're already within a transaction. There are two
		// implementation alternatives regarding `inTransaction`. Either, an
		// exception is raised to prevent nested transactions or the inner
		// transaction omits the begin transaction. However, the second
		// alternatives poses some difficulties when it comes to the
		// commit/rollback. Therefor, the first alternative is implemented.
		if ( [self inTransaction] ) {
			[NSException raise:@"Nested transactions"
						format:@"A nested transaction have been detected, this is not allowed."];
		}

		[self setInTransaction:YES];
		[self beginTransaction:transaction];

		BOOL commit = block(db);

		if ( commit ) {
			[self commit];
		} else {
			[self rollBack];
		}
		[self setInTransaction:NO];
	}];
}

- (void)queueTransactionWithBlock:(BOOL (^)(RASqlite *db))block
{
	[self queueTransaction:RASqliteTransactionDeferred withBlock:block];
}

#pragma mark -

- (NSNumber *)lastInsertId
{
	NSNumber __block *insertId;
	if ( ![self error] && [self database] ) {
		[self queueWithBlock:^(RASqlite *db) {
			insertId = [NSNumber numberWithLongLong:sqlite3_last_insert_rowid([self database])];
		}];
	}

	return insertId;
}

- (NSNumber *)rowCount
{
	NSNumber __block *count;
	if ( ![self error] && [self database] ) {
		[self queueWithBlock:^(RASqlite *db) {
			count = [NSNumber numberWithInt:sqlite3_changes([self database])];
		}];
	}

	return count;
}

#pragma mark - Logging

- (void)logWithMessage:(NSString *)message level:(RASqliteLogLevel)level file:(NSString *)file line:(int)line
{
	if ( level >= _RASqliteLogLevel ) {
		NSLog(@"<%@:(%d)> %@", file, line, message);
	}
}

@end