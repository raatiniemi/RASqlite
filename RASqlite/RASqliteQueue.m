//
//  RASqliteQueue.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-31.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RASqliteQueue.h"

@interface RASqliteQueue ()

@property (nonatomic, readwrite, strong) RASqlite *db;

@end

@implementation RASqliteQueue

@synthesize db = _db;

@end