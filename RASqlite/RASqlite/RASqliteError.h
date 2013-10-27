//
//  RASqliteError.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *RASqliteErrorDomain = @"me.raatiniemi.rasqlite.error";

typedef enum {
	RASqliteErrorOpen,
	RASqliteErrorClose,

	RASqliteErrorBind,
	RASqliteErrorQuery,
	RASqliteErrorImplementation
} RASqliteErrorCode;

@interface RASqliteError : NSError

+ (instancetype)code:(RASqliteErrorCode)code message:(NSString *)message, ...;

@end