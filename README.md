# [RASqlite](https://github.com/raatiniemi/RASqlite.git)
RASqlite is a simple and thread-safe Objective-C wrapper for working with Sqlite databases on the iOS and Mac OS X platforms. The interface is designed to be easy and fast to work with.

## Working with the library
### Initialization
The `RASqlite`-class have two initialization methods, `initWithPath:` and `initWithName:`. The former is the designated initializer which accepts the absolute path to the database file, this method should primarily be used on the OS X platform. The `initWithPath:` will create the directory path if it do not already exists.

	RASqlite *database = [[RASqlite alloc] initWithPath:@"/tmp/user.db"];

The `initWithName:` is especially designed for the iOS platform, it accepts the basename of the database file. The file will be placed within the `Documents`-directory.

	RASqlite *database = [[RASqlite alloc] initWithName:@"user.db"];

Note: Unless you want to open the database connection with specific options there's no reason to manually execute the `open`-method. When a database connection is needed and none is available, one will be opened. The default flags for initializing the database connection is `SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE`, hence if the database file do not exists it will be created.

## Fetching data
There're two groups of methods for fetching data, fetch everything and fetch one single row. Each group have three method available depending on the number of arguments you'd want to bind to the query.

### Fetch row
To fetch one single row without any arguments you'd use the `fetchRow:`-method, as displayed below.

	// Fetch one user from the database.
	NSDictionary *user = [database fetchRow:@"SELECT id, name FROM users ORDER BY date LIMIT 1"];
	if ( user ) {
		// The `fetchRow:`-method will return `nil` if no row was found.
		// Do something with the user.
	} else if ( ![database error] ) {
		// No users were found since user is `nil` and no database error had occurred.
	} else {
		// An error occurred, handle it.
		// It is important to reset the error, [database setError:nil], after the error had been handled.
		// Otherwise, no queries will be executed with the database instance.
	}

To bind argument(s) to your queries, you have to methods to choose from. The `fetchRow:withParams:`-method accepts an array of arguments, and the `fetchRow:withParam:`-method accepts a single object.

#### Fetch with multiple arguments.
	NSString *sql = @"SELECT foo FROM bar WHERE baz = ? OR qux = ? LIMIT 1";
	NSDictionary *row = [database fetchRow:sql withParams:@[@1, @"sample"]];

#### Fetch with a single argument.
	NSString *sql = @"SELECT foo FROM bar WHERE baz = ? LIMIT 1";
	NSDictionary *row = [database fetchRow:sql withParam:@1];

Note: Even if you omit the the `LIMIT 1` only the first row will be returned.
Note: Only `NSNumber` and `NSString` are supported.

### Fetch
To fetch more than one row without any arguments you'd use the `fetch:`-method, as displayed below.

	NSArray *result = [database fetch:@"SELECT foo, bar, baz FROM qux"];
	if ( [result count] > 0 ) {
		// The `fetch:`-method will return `nil` if no rows were found.
		// Do something with the rows.
	} else if ( ![database error] ) {
		// No rows were found since `result count` returns 0 and no database error have occurred.
	} else {
		// An error occurred, handle it.
		// It is important to reset the error, [database setError:nil], after the error had been handled.
		// Otherwise, no queries will be executed with the database instance.
	}

As with the `fetchRow`-method you can bind argument(s) to the query with the use of the `fetch:withParams:` and `fetch:withParam:` methods.

#### Fetch with multiple arguments.
	NSString *sql = @"SELECT foo FROM bar WHERE baz = ? OR qux = ?";
	NSDictionary *row = [database fetch:sql withParams:@[@1, @"sample"]];

#### Fetch with a single argument.
	NSString *sql = @"SELECT foo FROM bar WHERE baz = ?";
	NSDictionary *row = [database fetch:sql withParam:@1];

Note: Only `NSNumber` and `NSString` are supported.

## Insert/update data
To perform updates to the database, you'd want to use the `execute:`-methods.

	BOOL success = [database execute:@"INSERT INTO foo(bar) VALUES('baz')"];
	if ( success ) {
		// The row have been inserted.
	} else {
		// Something went wrong, handle the error.
	}

As with the fetch methods you can bind argument(s) to the query. The `execute:withParams:`-method accepts an array with objects, and the `execute:withParam:`-method accepts a single object.

### Insert/update with multiple arguments.
	NSString *sql = @"UPDATE foo SET bar = ? WHERE baz = ?";
	BOOL success = [database execute:sql withParams:@[@"qux", @1]];

### Insert/update with a single argument.
	NSString *sql = @"INSERT INTO foo(bar) VALUES(?)";
	BOOL success = [database execute:sql withParam:@"qux"];

Note: Only `NSNumber` and `NSString` are supported, support for `NSData` (i.e. Sqlite `blob`) is coming.

## Validation
If you use the supplied methods, in the designed way, for executing your queries, you do not have to worry about SQL-injections. Since each of the method internally use `sqlite3_prepare_v2` and `sqlite3_bind_*` the protection against SQL-injections are already taken cared of.

Note: You should however still have an application layer for validation, i.e. validate that the users input data is within reasonable limits. E.g. the age of a person do not exceed 200 years.

## Thread safety
When using a single instance of the database, each of the query methods are thread-safe. However, if you are executing queries with multiple instances against the same database it is highly recommended that you extend the `RASqlite`-class and override these methods:

1. `setDatabase:`
2. `database`

These methods should point to a static `sqlite3` variable, as shown below.

	static sqlite3 *_database;
	@implementation RASqliteThreadSafe
	- (void)setDatabase:(sqlite3 *)database
	{
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			_database = database;
		});
	}
	- (sqlite3 *)database
	{
		return _database;
	}
	@end

By overriding the `setDatabase:` and `database` methods you also gain a performance boost since each new database instance do not have to open the connection again. However, the memory imprint will be marginally increased, this should not be an issue unless you have a lot of different databases.

## Working with queues
The query methods are always executed on the same database instance queue. However, if you are executing queries from multiple different threads it is not always guaranteed that the queries are executed in the order you'd want. In these situations you should use the `queueWithBlock:`-method.

	NSNumber __block *rowId;
	[database queueWithBlock:^(RASqlite *db) {
		BOOL success = [db execute:@"INSERT INTO foo(bar) VALUES('baz')"];
		if ( success ) {
			rowId = [db lastInsertId];
		}
	}];
	if ( rowId ) {
		// Do something with the row.
	} else {
		// An error occurred.
	}

## Working with transactions
There're scenarios where you'd want to attempt an update on multiple rows or tables, and if one update fails everything should be restored. This is where you'd want to use transactions. There're support for three different types of transactions, and which you'd want to use depends on your needs.

1. `DEFERRED` - No locks are acquired on the database until the database is first accessed.
1. `IMMEDIATE` - Reserved locks are acquired on all database, without waiting for database access.
1. `EXCLUSIVE` - An exclusive transaction causes EXCLUSIVE locks to be acquired on all databases.

And, the equivalent RASqlite transaction types are as follows.

1. `RASqliteTransactionDeferred`
2. `RASqliteTransactionImmediate`
3. `RASqliteTransactionExclusive`

There're two methods available when working with transactions. With the `queueTransaction:withBlock:`-method you can specify which type of transaction you'd want to use, and with the `queueTransactionWithBlock:`-method the default type is used (which is deferred).

	[database queueTransaction:RASqliteTransactionExclusive withBlock:^(RASqlite *db, BOOL *commit) {
		*commit = [db execute:@"DELETE FROM foo WHERE bar = ?" withParam:@"baz"];
		if ( *commit ) {
			*commit = [db execute:@"DELETE FROM bar WHERE baz = ?" withParam:@"qux"];
		}
	 }];

The block method is supplied with two methods, first argument is the database instance, and the second argument is the boolean which controls whether the transaction should be committed or rolled back.

In the above scenario if both `execute:withParam:`-calls is successful, the `commit`-variable will evaluate to `YES`, i.e. the transaction will be committed.

## Error handling
Coming soon...

## Logging
The default mechanism for logging messages uses the `NSLog`-macro. The message will include the filename and line number from which the log message originated. There're four different log levels available.

1. `RASqliteLogLevelDebug`
2. `RASqliteLogLevelInfo`
3. `RASqliteLogLevelWarning`
4. `RASqliteLogLevelError`

By default, if the `DEBUG`-constant is defined every log level will be logged. If the constant is not defined only warnings and errors will be logged.

### Third party loggers
If you'd rather use a third party logging method, all you have to do is override the `RASqliteLog`-macro. If you choose to do this, there're two things that you should be aware of.

1. The file you define your custom macro in have to be imported within the `*-Prefix.pch` file, otherwise the `ifndef`-check will not recognize your macro and the default one will be used.
2. The arguments for the macro can not be modified. The first argument is the log level and the second one is the message with support for formats.

It is highly recommended that you copy the default macro and make your adjustments within the `do-while`.

## Check, create, and delete tables
Coming soon...