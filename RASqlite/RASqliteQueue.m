//
//  RASqliteQueue.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-31.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RASqlite.h"
#import "RASqliteQueue.h"

@interface RASqliteQueue () {
@private RASqlite *_database;
}

@property (nonatomic, readwrite, strong) RASqlite *database;

@end

@implementation RASqliteQueue

@synthesize database = _database;

#pragma mark - Initialization

- (instancetype)initWithDatabase:(RASqlite *)database
{
	if ( self = [super init] ) {
		[self setDatabase:database];

		// Assemble the thread name using the representation of the database instance.
		// The database instance is static, and each instance should only be used
		// for one database file, which makes it the perfect unique identifier.
		NSString *thread = [NSString stringWithFormat:kRASqliteThreadFormat, [database database]];
		_queue = dispatch_queue_create([thread UTF8String], NULL);
	}
	return self;
}

#pragma mark - Execute

- (void)queueWithBlock:(void (^)(RASqlite *db))block
{
	dispatch_sync(_queue, ^{
		block([self database]);
	});
}

- (void)beginTransactionType:(NSInteger)type withBlock:(void (^)(RASqlite *db, BOOL *commit))block
{
}

- (void)transactionType:(NSInteger)type withBlock:(void (^)(RASqlite *db, BOOL *commit))block
{
	// Begin specified type transaction.
}

- (void)transactionWithBlock:(void (^)(RASqlite *db, BOOL *commit))block
{
	// Begin deferred transaction.
}

@end