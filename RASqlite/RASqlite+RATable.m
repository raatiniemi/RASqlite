//
//  RASqlite+RATable.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-05-24.
//  Copyright (c) 2014 Raatiniemi. All rights reserved.
//

#import "RASqlite+RATable.h"

// -- -- Exception

/// Exception name for issues with checking of database structure.
static NSString *RASqliteCheckDatabaseException = @"Check database";

/// Exception name for issues with checking of table structure.
static NSString *RASqliteCheckTableException = @"Check table";

/// Exception name for issues with table removal.
static NSString *RASqliteRemoveTableException = @"Remove table";

@implementation RASqlite (RATable)

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
		[self queueWithBlock:^(RASqlite *db) {
			NSDictionary *tables = [db structure];
			if ( tables ) {
				// Get the pointer for the method, performance improvement.
				SEL selector = @selector(checkTable:withColumns:);

				typedef BOOL (*check) (id, SEL, NSString*, NSDictionary*);
				check checkTable = (check)[db methodForSelector:selector];

				for ( NSString *table in tables ) {
					if ( !checkTable(db, selector, table, [tables objectForKey:table]) ) {
						valid = NO;
						break;
					}
				}
			} else {
				// Raise an exception, no structure have been supplied.
				[NSException raise:RASqliteCheckDatabaseException
							format:@"Unable to check database structure, none has been supplied."];
			}
		}];
	}

	return valid;
}

- (BOOL)checkTable:(NSString *)table withColumns:(NSArray *)columns
{
	if ( !table ) {
		// Raise an exception, no valid table name.
		[NSException raise:RASqliteCheckTableException
					format:@"Unable to check table without valid name."];
	}

	if ( !columns ) {
		// Raise an exception, no defined columns.
		[NSException raise:RASqliteCheckTableException
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
		[self queueWithBlock:^(RASqlite *db) {
			// Check whether the defined columns and the table columns match.
			NSArray *tColumns = [db fetch:[NSString stringWithFormat:@"PRAGMA table_info(%@)", table]];
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
		}];
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
		[self queueWithBlock:^(RASqlite *db) {
			NSDictionary *tables = [self structure];
			if ( tables ) {
				// Get the pointer for the method, performance improvement.
				SEL selector = @selector(createTable:withColumns:);

				typedef BOOL (*create) (id, SEL, NSString*, NSDictionary*);
				create createTable = (create)[db methodForSelector:selector];

				// Change the created check before going in to the create loop.
				created = YES;

				// Loops through each of the tables and attempt to create their structure.
				for ( NSString *table in tables ) {
					if ( !createTable(db, selector, table, [tables objectForKey:table]) ) {
						created = NO;
						break;
					}
				}
			} else {
				// Raise an exception, no structure have been supplied.
				[NSException raise:RASqliteCheckDatabaseException
							format:@"Unable to create database structure, none has been supplied."];
			}
		}];
	}

	return created;
}

- (BOOL)createTable:(NSString *)table withColumns:(NSDictionary *)columns
{
	if ( !table ) {
		// Raise an exception, no valid table name.
		[NSException raise:RASqliteCheckTableException
					format:@"Unable to create table without valid name."];
	}

	if ( !columns ) {
		// Raise an exception, no defined columns.
		[NSException raise:RASqliteCheckTableException
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
		[self queueWithBlock:^(RASqlite *db) {
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
			created = [db execute:sql];
			if ( created ) {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` have been created.", table);
			} else {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` have not been created.", table);
			}
		}];
	}

	return created;
}

- (BOOL)deleteTable:(NSString *)table
{
	if ( !table ) {
		// Raise an exception, no valid table name.
		[NSException raise:RASqliteRemoveTableException
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
		[self queueWithBlock:^(RASqlite *db) {
			// Attempt to remove the database table.
			removed = [db execute:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", table]];
			if ( removed ) {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` have been removed.", table);
			} else {
				RASqliteLog(RASqliteLogLevelDebug, @"Table `%@` have not been removed.", table);
			}
		}];
	}
	
	return removed;
}

@end