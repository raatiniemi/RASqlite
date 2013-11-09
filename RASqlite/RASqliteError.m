//
//  RASqliteError.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-10-27.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "RASqliteError.h"
#import "RASqlite.h"

@implementation RASqliteError

+ (instancetype)code:(RASqliteErrorCode)code message:(NSString *)message, ...
{
	// Retrieve the full error message with format arguments.
	va_list args;
	va_start(args, message);
	message = [[NSString alloc] initWithFormat:message arguments:args];
	va_end(args);
	RASqliteLog(@"Error with message: `%@`", message);

	// Assemble the localized description.
	NSDictionary *userInfo = @{NSLocalizedDescriptionKey: message};
	return [[self class] errorWithDomain:RASqliteErrorDomain code:code userInfo:userInfo];
}

@end