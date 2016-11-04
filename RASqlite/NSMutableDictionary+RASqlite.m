//
//  NSMutableDictionary+RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-14.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import "NSMutableDictionary+RASqlite.h"

@implementation NSMutableDictionary (RASqlite)

- (void)setColumn:(NSString *)name withObject:(id)object
{
	// Incase the object value is `nil` we have to change the value to `NSNull`.
	if ( object == nil ) {
		object = [NSNull null];
	}

	[self setObject:object forKey:name];
}

@end