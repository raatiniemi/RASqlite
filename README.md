# [RASqlite](https://github.com/raatiniemi/RASqlite.git)

RASqlite is a simple library for working with SQLite databases on iOS and Mac OS X. The interface is designed to be easy to work with.

## Fetching data

	// Initialize with the database filename. The `initWithName:´ method will,
	// when opened, create a database within the Documents folder.
	RASqlite *database = [[RASqlite alloc] initWithName:@"user.db"];

	// Fetch one user from the database.
	NSDictionary *user = [database fetchRow:@"SELECT id, name FROM users LIMIT 1"];
	if ( user ) {
		// Do something with the user.
	} else if ( ![database error] ) {
		// No users were found.
	} else {
		// An error occurred, handle it.
	}

To bind argument(s) to the query, simply use the `fetchRow:withParams:` or `fetchRow:withParam:` methods. The `withParams:` method accepts an array of objects, and the `withParam:` accepts a single object. Acceptable objects are `NSNumber` and `NSString`.

	NSDictionary *row = [database fetchRow:@"SELECT foo FROM bar WHERE baz = ? AND qux = ?" withParams:@[@1, @2]];
	NSDictionary *row = [database fetchRow:@"SELECT foo FROM bar WHERE baz = ?" withParam:@1];

To fetch more than one row, use the `fetch:` method.

	NSArray *result = [database fetch:@"SELECT foo, bar, baz FROM qux"];
	if ( [result count] > 0 ) {
		// Do something with the results.
	} else if ( ![database error] ) {
		// No result was found.
	} else {
		// An error occurred, handle it.
	}

The `fetch:` method also have argument binding alternatives, `fetch:withParams:` and `fetch:withParam:`. And, as with the `fetchRow:` method the `withParams:` method accepts an array and the `withParam:` accepts a single object.

## Update data

To perform an update to the database, use the `execute:` method.

	// The execute methods return a BOOL value.
	BOOL success = [database execute:@"UPDATE foo SET bar = 'baz' WHERE qux = 1"];
	if ( success ) {
		// The database have been updated.
	} else {
		// Something went wrong, handle the error.
	}

As with both the `fetchRow:` and `fetch:` methods the `execute:` method also have a way of binding argument(s) to the query.

	BOOL success = [database execute:@"UPDATE foo SET bar = ? WHERE baz = ?" withParams:@[@1, @2]];
	BOOL success = [database execute:@"UPDATE foo SET bar = 'baz' WHERE qux = ?" withParam:@1];

## Queues

Each of the query methods are executed on the same queue, i.e. the methods is thread safe. The queue on which the queries are executed on is unique for the database filename, if the `initWithName:` method is used. The queue label is formatted as follows, `me.raatiniemi.rasqlite.` and the database filename is suffixed, i.e. `me.raatiniemi.rasqlite.user.db` as from the example above.

The query methods are by them self executed on the database queue. However, there're situations where you'd want to queue multiple queries.

	NSDictionary __block *row;
	[self queueWithBlock:^(RASqlite *db) {
		row = [db fetchRow:@"SELECT foo FROM bar WHERE baz = ?" withParam:@"qux"];
	}];
	// Do something with row.