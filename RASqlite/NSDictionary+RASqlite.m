//
//  NSDictionary+RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-14.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import "NSDictionary+RASqlite.h"

@implementation NSDictionary (RASqlite)

- (id)getColumn:(NSString *)name {
    return [self hasColumn:name] ? self[name] : [NSNull null];
}

- (BOOL)hasColumn:(NSString *)name {
    return self[name] != nil;
}

@end