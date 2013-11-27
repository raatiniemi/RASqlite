//
//  RASqliteColumn.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RASqliteColumn.h"

@interface RASqliteColumn () {
}

@property (nonatomic, readwrite, strong) NSString *name;

@property (nonatomic, readwrite, strong) NSString *type;

@end

@implementation RASqliteColumn

- (instancetype)initWithName:(NSString *)name type:(NSString *)type
{
	if ( self = [super init] ) {
	}
	return self;
}

@end