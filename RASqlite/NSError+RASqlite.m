//
//  NSError+RASqlite.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-13.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import "NSError+RASqlite.h"
#import "RASqlite.h"

@implementation NSError (RASqlite)

+ (instancetype)code:(RASqliteErrorCode)code message:(NSString *)message, ...
{
	// Retrieve the full error message with format arguments.
	va_list args;
	va_start(args, message);
	message = [[NSString alloc] initWithFormat:message arguments:args];
	va_end(args);

	RASqliteLog(@"An error has occurred: %@", message);

	// Assemble the localized description.
	NSDictionary *userInfo = @{NSLocalizedDescriptionKey: message};
	return [[self class] errorWithDomain:RASqliteErrorDomain code:code userInfo:userInfo];
}

@end