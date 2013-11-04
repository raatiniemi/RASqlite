//
//  RASqliteRow.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RASqliteRow.h"

@interface RASqliteRow () {
@private NSMutableDictionary *_data;
}

@property (nonatomic, readwrite, strong) NSMutableDictionary *data;

@end

@implementation RASqliteRow

@synthesize data = _data;

#pragma mark - Initialization

+ (instancetype)columns:(NSUInteger)columns
{
	RASqliteRow *row = [[RASqliteRow alloc] init];
	[row setData:[[NSMutableDictionary alloc] initWithCapacity:columns]];

	return row;
}

#pragma mark - Container manipulation

- (id)getColumn:(NSString *)name
{
	return [self hasColumn:name] ? [[self data] objectForKey:name] : [NSNull null];
}

- (void)setColumn:(NSString *)name withValue:(id)value
{
	if ( value == nil ) {
		value = [NSNull null];
	}
	[[self data] setObject:value forKey:name];
}

- (BOOL)hasColumn:(NSString *)name
{
	return [[self data] objectForKey:name] != nil;
}

- (NSUInteger)count
{
	return [[self data] count];
}

@end