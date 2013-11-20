//
//  NSError+RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-13.
//  Copyright (c) 2013 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Error domain for RASqlite related errors.
static NSString *RASqliteErrorDomain = @"me.raatiniemi.rasqlite.error";

/// Defined error codes for the library.
typedef enum {
	RASqliteErrorOpen,
	RASqliteErrorClose,
	RASqliteErrorBind,
	RASqliteErrorQuery,
	RASqliteErrorTransaction
} RASqliteErrorCode;

/**
 Simplified handling for RASqlite errors.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
@interface NSError (RASqlite)

/**
 Creates an error object with code and message, with support for formats.

 @param code Code for the error.
 @param message Message for the error, with support for formats.

 @code
 [NSError code:RASqliteErrorOpen message:@"Unable to open, message: %@", message];
 @endcode

 @return Instansiated error, with domain, code, and localized description.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>
 */
+ (instancetype)code:(RASqliteErrorCode)code message:(NSString *)message, ...;

@end