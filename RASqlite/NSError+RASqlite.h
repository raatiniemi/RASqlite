//
//  NSError+RASqlite.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-11-13.
//  Copyright (c) 2013-2016 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Defined error codes for the library.
typedef NS_ENUM(short int, RASqliteErrorCode) {
	/// Error code related to open the database.
	RASqliteErrorOpen,

	/// Error code related to close the database.
	RASqliteErrorClose,

	/// Error code related to binding data.
	RASqliteErrorBind,

	/// Error code related to executing queries.
	RASqliteErrorQuery,

	/// Error code related to transaction.
	RASqliteErrorTransaction
};

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