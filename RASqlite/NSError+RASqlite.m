//
//  NSError+RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-13.
//  Copyright (c) 2013-2014 Raatiniemi. All rights reserved.
//

#import "NSError+RASqlite.h"

/// Error domain for RASqlite related errors.
static NSString *RASqliteErrorDomain = @"me.raatiniemi.rasqlite.error";

@implementation NSError (RASqlite)

+ (instancetype)code:(RASqliteErrorCode)code message:(NSString *)message, ...
{
	// Retrieve the full error message with format arguments.
	if ( message ) {
		// Assemble the message with format and arguments.
		va_list args;
		va_start(args, message);
		message = [[NSString alloc] initWithFormat:message arguments:args];
		va_end(args);
	} else {
		// No message have been supplied, use default message.
		message = @"No error message have been supplied.";
	}

	// Assemble the localized description.
	NSDictionary *userInfo = @{NSLocalizedDescriptionKey: message};
	return [[self class] errorWithDomain:RASqliteErrorDomain code:code userInfo:userInfo];
}

@end