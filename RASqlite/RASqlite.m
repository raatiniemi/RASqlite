//
//  RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import "RASqlite.h"

// -- -- Exception

/// Exception name for incorrect initialization.
static NSString *RASqliteIncorrectInitializationException = @"Incorrect initialization";

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

#import "RASqliteBinder.h"
#import "RASqliteMapper.h"
#import "RASqliteQueue.h"

/**
 RASqlite is a simple library for working with SQLite databases on iOS and Mac OS X.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface RASqlite () {
@private
    sqlite3 *_database;

    RASqliteQueue *_queue;

    NSString *_path;
}

/// Stores the path for the database file.
@property(strong, atomic) NSString *path;

/// Number of attempts before the retry timeout is reached.
@property(atomic) NSUInteger maxNumberOfRetriesBeforeTimeout;

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

#pragma mark - Database

/**
 Check whether a database connection is available or can be opened.

 @return `YES` if connection is available or can be opened, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)isConnectionOpenOrCanBeOpened;

#pragma mark - Query

/**
 Bind the parameters to the statement.

 @param parameters Parameters to bind to the statement.
 @param statement Statement on which the parameters will be binded.

 @return `YES` if binding is successful, otherwise `NO`.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
- (BOOL)bindParameters:(NSArray *)parameters toStatement:(sqlite3_stmt **)statement;

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

@end

@implementation RASqlite

@synthesize path = _path;

@synthesize error = _error;

#pragma mark - Initialization

- (id)init {
    // TODO: Implement support for in memory databases with init as method?
    // Use designated initializer, e.g. from the `init` method run the
    // `initWithPath:`. If the path is @"" or `nil` the database should be
    // initialized as memory database.

    // Use of this method is not allowed, `initWithName:` or `initWithPath:` should be used.
    [NSException raise:RASqliteIncorrectInitializationException
                format:@"Use of the `init` method is not allowed, use `initWithName:` or `initWithPath:` instead."];

    // Return nil, takes care of the return warning.
    return nil;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        // Check if the path is writeable, among other things.
        if (![self checkPath:path]) {
            // There is something wrong with the path, raise an exception.
            [NSException raise:RASqliteInvalidPathException
                        format:@"The supplied path `%@` can not be used.", path];
        }
        // Assign the database path.
        [self setPath:path];

        _queue = [RASqliteQueue sharedQueue];

        // Set the number of retry attempts before a timeout is triggered.
        self.maxNumberOfRetriesBeforeTimeout = 0;
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name {
    // Assemble the path for the database file.
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [self initWithPath:RASqliteSF(@"%@/%@", directories[0], name)];
}

#pragma mark - Path

- (BOOL)checkPath:(NSString *)path {
    // Check that a path actually have been supplied.
    if (path == nil) {
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

        if (exists && !isDirectory) {
            directory = [directory stringByDeletingLastPathComponent];
            continue;
        }

        // If the path do not exists, we need to create it.
        if (!exists) {
            // Attempt to create the directory.
            BOOL created = [manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
            if (!created) {
                RASqliteErrorLog(@"Unable to create directory `%@` with error: %@", directory, [error localizedDescription]);
                break;
            }
        }

        BOOL readable = [manager isReadableFileAtPath:directory];
        BOOL writeable = [manager isWritableFileAtPath:directory];

        // Check that the directory is both readable and writeable.
        if (!readable || !writeable) {
            [NSException raise:RASqliteFilesystemPermissionException
                        format:@"The directory `%@` need to be readable and writeable.", directory];
        }

        isValidDirectory = YES;
    } while (!isValidDirectory);

    return isValidDirectory;
}

#pragma mark - Database

- (BOOL)openWithFlags:(int)flags {
    NSError __block *error;

    [_queue dispatchBlock:^{
        // Check if the database already is active, not need to open it.
        if (_database) {
            // No need to attempt to open the database, it's already open.
            RASqliteDebugLog(@"Database is already open.");
            return;
        }

        // Attempt to open the database.
        int code = sqlite3_open_v2([[self path] UTF8String], &_database, flags, NULL);
        if (code == SQLITE_OK) {
            // The database was successfully opened.
            RASqliteInfoLog(@"Database `%@` have successfully been opened.", [[self path] lastPathComponent]);
            return;
        }

        // Something went wrong...
        const char *errmsg = sqlite3_errmsg(_database);
        NSString *message = RASqliteSF(@"Unable to open database: %s", errmsg);
        RASqliteErrorLog(@"%@", message);

        error = [NSError code:RASqliteErrorOpen message:message];
        [self setError:error];
    }];

    return error == nil;
}

- (BOOL)open {
    return [self openWithFlags:SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE];
}

- (BOOL)close {
    NSError __block *error;

    [_queue dispatchBlock:^{
        if (_database) {
            RASqliteDebugLog(@"Database is already closed.");
            return;
        }

        // We have to check whether we have an active transaction. The
        // `sqlite3_close` will close the database even if a transaction
        // lock have been acquired.
        if ([self inTransaction]) {
            // TODO: We should not return `YES` if we did not close the database.
            return;
        }

        int code;

        // Checks of number of attempts, will prevent infinite loops.
        NSInteger attempt = 0;

        // Repeat the close process until the database is closed, an error
        // occurs, or the retry attempts have been depleted.
        do {
            code = sqlite3_close(_database);
            if (SQLITE_OK == code) {
                _database = nil;
                RASqliteInfoLog(@"Database `%@` have successfully been closed.", [[self path] lastPathComponent]);
                return;
            }

            // Check whether the database is busy or locked.
            // By default, sqlite3 do not check if a transaction is
            // active this has to be manually checked.
            if (code == SQLITE_BUSY || code == SQLITE_LOCKED) {
                attempt++;

                if (attempt > self.maxNumberOfRetriesBeforeTimeout) {
                    RASqliteInfoLog(@"Retry timeout have been reached, unable to close database.");
                    break;
                }

                // Since every query against the same database is executed
                // on the same queue it is highly unlikely that the database
                // would be busy or locked, but better to be safe.
                RASqliteInfoLog(@"Database is busy/locked, retrying to close.");
                continue;
            } else {
                // Something went wrong...
                const char *errmsg = sqlite3_errmsg(_database);
                NSString *message = RASqliteSF(@"Unable to close database: %s", errmsg);
                RASqliteErrorLog(@"%@", message);

                error = [NSError code:RASqliteErrorClose message:message];
                [self setError:error];
            }
        } while (NO);
    }];

    return error == nil;
}

- (BOOL)isConnectionOpenOrCanBeOpened {
    return _database || [self open];
}

#pragma mark - Query

- (BOOL)bindParameters:(NSArray *)parameters toStatement:(sqlite3_stmt **)statement {
    NSError *error = [RASqliteBinder bindParameters:parameters toStatement:statement];
    if (error) {
        [self setError:error];
    }

    return error == nil;
}

#pragma mark -- Fetch

- (NSArray *)fetch:(NSString *)sql withParams:(NSArray *)params {
    NSMutableArray __block *results;

    [_queue dispatchBlock:^{
        if (self.isConnectionOpenOrCanBeOpened) {
            NSError __block *error;

            sqlite3_stmt *statement;
            int code = sqlite3_prepare_v2(_database, [sql UTF8String], -1, &statement, NULL);

            if (code == SQLITE_OK) {
                // If we have parameters, we need to bind them to the statement.
                if (!params || [self bindParameters:params toStatement:&statement]) {
                    // Get the pointer for the method, performance improvement.
                    SEL selector = @selector(fetchColumns:);

                    typedef NSDictionary *(*fetch)(id, SEL, sqlite3_stmt **);
                    fetch fetchColumns = (fetch) [[RASqliteMapper class] methodForSelector:selector];

                    NSDictionary *row;
                    results = [[NSMutableArray alloc] init];

                    // Looping through the results, until an error occurs or
                    // the query is done.
                    do {
                        code = sqlite3_step(statement);

                        if (code == SQLITE_ROW) {
                            row = fetchColumns(self, selector, &statement);
                            [results addObject:row];
                        } else if (code == SQLITE_DONE) {
                            // Results have been fetch, leave the loop.
                            break;
                        } else {
                            // Something has gone wrong, leave the loop.
                            const char *errmsg = sqlite3_errmsg(_database);
                            NSString *message = RASqliteSF(@"Unable to fetch row: %s", errmsg);
                            RASqliteErrorLog(@"%@", message);

                            error = [NSError code:RASqliteErrorQuery message:message];
                            [self setError:error];

                            // Since an error has occurred we need to reset the results.
                            results = nil;
                        }
                    } while (!error);
                }
            } else {
                // Something went wrong...
                const char *errmsg = sqlite3_errmsg(_database);
                NSString *message = RASqliteSF(@"Failed to prepare statement `%@`: %s", sql, errmsg);
                RASqliteErrorLog(@"%@", message);

                error = [NSError code:RASqliteErrorQuery message:message];
                [self setError:error];
            }
            sqlite3_finalize(statement);
        }
    }];

    return results;
}

- (NSArray *)fetch:(NSString *)sql withParam:(id)param {
    return [self fetch:sql withParams:@[param]];
}

- (NSArray *)fetch:(NSString *)sql {
    return [self fetch:sql withParams:nil];
}

- (NSDictionary *)fetchRow:(NSString *)sql withParams:(NSArray *)params {
    NSDictionary __block *row;

    [_queue dispatchBlock:^{
        if (self.isConnectionOpenOrCanBeOpened) {
            NSError *error;

            sqlite3_stmt *statement;
            int code = sqlite3_prepare_v2(_database, [sql UTF8String], -1, &statement, NULL);

            if (code == SQLITE_OK) {
                // If we have parameters, we need to bind them to the statement.
                if (!params || [self bindParameters:params toStatement:&statement]) {
                    code = sqlite3_step(statement);
                    if (code == SQLITE_ROW) {
                        row = [[RASqliteMapper class] fetchColumns:&statement];

                        // If the error variable have been populated, something
                        // has gone wrong and we need to reset the row variable.
                        if (error || [row count] == 0) {
                            row = nil;
                        }
                    } else if (code == SQLITE_DONE) {
                        RASqliteDebugLog(@"No rows were found with query: %@", sql);
                    } else {
                        // Something went wrong...
                        const char *errmsg = sqlite3_errmsg(_database);
                        NSString *message = RASqliteSF(@"Failed to retrieve result: %s", errmsg);
                        RASqliteErrorLog(@"%@", message);

                        error = [NSError code:RASqliteErrorQuery message:message];
                        [self setError:error];
                    }
                }
            } else {
                // Something went wrong...
                const char *errmsg = sqlite3_errmsg(_database);
                NSString *message = RASqliteSF(@"Failed to prepare statement `%@`: %s", sql, errmsg);
                RASqliteErrorLog(@"%@", message);

                error = [NSError code:RASqliteErrorQuery message:message];
                [self setError:error];
            }
            sqlite3_finalize(statement);
        }
    }];

    return row;
}

- (NSDictionary *)fetchRow:(NSString *)sql withParam:(id)param {
    return [self fetchRow:sql withParams:@[param]];
}

- (NSDictionary *)fetchRow:(NSString *)sql {
    return [self fetchRow:sql withParams:nil];
}

#pragma mark -- Update

- (BOOL)execute:(NSString *)sql withParams:(NSArray *)params {
    BOOL __block success = NO;

    [_queue dispatchBlock:^{
        if (self.isConnectionOpenOrCanBeOpened) {
            NSError *error;

            sqlite3_stmt *statement;
            int code = sqlite3_prepare_v2(_database, [sql UTF8String], -1, &statement, NULL);

            if (code == SQLITE_OK) {
                // If we have parameters, we need to bind them to the statement.
                if (!params || [self bindParameters:params toStatement:&statement]) {
                    code = sqlite3_step(statement);
                    if (code == SQLITE_DONE) {
                        // Statement have been successfully executed.
                        success = YES;
                    } else {
                        // Something went wrong...
                        const char *errmsg = sqlite3_errmsg(_database);
                        NSString *message = RASqliteSF(@"Failed to execute query: %s", errmsg);
                        RASqliteErrorLog(@"%@", message);

                        error = [NSError code:RASqliteErrorQuery message:message];
                        [self setError:error];
                    }
                }
            } else {
                // Something went wrong...
                const char *errmsg = sqlite3_errmsg(_database);
                NSString *message = RASqliteSF(@"Failed to prepare statement `%@`: %s", sql, errmsg);
                RASqliteErrorLog(@"%@", message);

                error = [NSError code:RASqliteErrorQuery message:message];
                [self setError:error];
            }
            sqlite3_finalize(statement);
        }
    }];

    return success;
}

- (BOOL)execute:(NSString *)sql withParam:(id)param {
    return [self execute:sql withParams:@[param]];
}

- (BOOL)execute:(NSString *)sql {
    return [self execute:sql withParams:nil];
}

#pragma mark -- Transaction

- (BOOL)beginTransaction:(RASqliteTransaction)type {
    BOOL __block success = NO;

    [_queue dispatchBlock:^{
        if (self.isConnectionOpenOrCanBeOpened) {
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
            int code = sqlite3_exec(_database, sql, 0, 0, &errmsg);

            success = (code == SQLITE_OK);
            if (!success) {
                NSString *message = [NSString stringWithCString:errmsg encoding:NSUTF8StringEncoding];
                RASqliteErrorLog(@"Unable to begin transaction: %@", message);

                NSError *error = [NSError code:RASqliteErrorTransaction message:message];
                [self setError:error];
            }
        }
    }];

    return success;
}

- (BOOL)beginTransaction {
    return [self beginTransaction:RASqliteTransactionDeferred];
}

- (BOOL)rollBack {
    BOOL __block success = NO;

    [_queue dispatchBlock:^{
        char *errmsg;
        int code = sqlite3_exec(_database, "ROLLBACK TRANSACTION", 0, 0, &errmsg);

        success = (code == SQLITE_OK);
        if (!success) {
            NSString *message = [NSString stringWithCString:errmsg encoding:NSUTF8StringEncoding];
            RASqliteErrorLog(@"Unable to rollback transaction: %@", message);

            NSError *error = [NSError code:RASqliteErrorTransaction message:message];
            [self setError:error];
        }
    }];

    return success;
}

- (BOOL)commit {
    BOOL __block success = NO;

    [_queue dispatchBlock:^{
        char *errmsg;
        int code = sqlite3_exec(_database, "COMMIT TRANSACTION", 0, 0, &errmsg);

        success = (code == SQLITE_OK);
        if (!success) {
            NSString *message = [NSString stringWithCString:errmsg encoding:NSUTF8StringEncoding];
            RASqliteErrorLog(@"Unable to commit transaction: %@", message);

            NSError *error = [NSError code:RASqliteErrorTransaction message:message];
            [self setError:error];
        }
    }];

    return success;
}

- (BOOL)inTransaction {
    BOOL __block inTransaction = NO;

    [_queue dispatchBlock:^{
        // Using the `sqlite3_get_autocommit` to check whether the database is
        // currently in a transaction.
        // http://sqlite.org/c3ref/get_autocommit.html
        if (self.isConnectionOpenOrCanBeOpened) {
            inTransaction = sqlite3_get_autocommit(_database) == 0;
        }
    }];

    return inTransaction;
}

#pragma mark -- Queue

- (void)queueWithBlock:(void (^)(RASqlite *db))block {
    [_queue dispatchBlock:^{
        block(self);
    }];
}

- (void)queueTransaction:(RASqliteTransaction)transaction withBlock:(void (^)(RASqlite *db, BOOL *commit))block {
    [self queueWithBlock:^(RASqlite *db) {
        // Check if we're already within a transaction. There are two
        // implementation alternatives regarding `inTransaction`. Either, an
        // exception is raised to prevent nested transactions or the inner
        // transaction omits the begin transaction. However, the second
        // alternatives poses some difficulties when it comes to the
        // commit/rollback. Therefor, the first alternative is implemented.
        if ([self inTransaction]) {
            [NSException raise:RASqliteNestedTransactionException
                        format:@"A nested transaction have been detected, this is not allowed."];
        }
        [self beginTransaction:transaction];

        BOOL commit = NO;
        block(db, &commit);

        if (commit) {
            [self commit];
        } else {
            [self rollBack];
        }
    }];
}

- (void)queueTransactionWithBlock:(void (^)(RASqlite *db, BOOL *commit))block {
    [self queueTransaction:RASqliteTransactionDeferred withBlock:block];
}

#pragma mark -- Helper

- (NSNumber *)lastInsertId {
    NSNumber __block *insertId;

    [_queue dispatchBlock:^{
        if (_database) {
            insertId = @(sqlite3_last_insert_rowid(_database));
        }
    }];

    return insertId;
}

- (NSNumber *)rowCount {
    NSNumber __block *count;

    [_queue dispatchBlock:^{
        if (_database) {
            count = @(sqlite3_changes(_database));
        }
    }];

    return count;
}

@end
