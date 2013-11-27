//
//  RASqliteColumn.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RASqliteColumn : NSObject {
@protected NSString *_name;
@protected NSString *_type;
}

@property (nonatomic, readonly, strong) NSString *name;

@property (nonatomic, readonly, strong) NSString *type;

- (instancetype)initWithName:(NSString *)name type:(NSString *)type;

@end