//
//  NSDictionary+RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-14.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "NSDictionary+RASqlite.h"

@implementation NSDictionary (RASqlite)

- (id)getColumn:(NSString *)name
{
	return [self hasColumn:name] ? [self objectForKey:name] : [NSNull null];
}

- (BOOL)hasColumn:(NSString *)name
{
	// The `objectForKey:` method returns `nil` if the key do not exists.
	return [self objectForKey:name] != nil;
}

@end