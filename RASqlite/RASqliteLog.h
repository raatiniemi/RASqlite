//
//  RASqliteLog.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2016-11-27.
//  Copyright (C) 2016 Raatiniemi. All rights reserved.
//

#ifndef RASqliteLog_h
#define RASqliteLog_h

/// Definition of available log levels.
typedef NS_ENUM(short int, RASqliteLogLevel) {
    /// Debug-level messages.
    RASqliteLogLevelDebug,

    /// Informational-level messages.
    RASqliteLogLevelInfo,

    /// Warning-level messages.
    RASqliteLogLevelWarning,

    /// Error-level messages.
    RASqliteLogLevelError
};

#if kRASqliteDebug
/// Stores the level of logging within the library.
static const RASqliteLogLevel _RASqliteLogLevel = RASqliteLogLevelDebug;
#else
/// Stores the level of logging within the library.
static const RASqliteLogLevel _RASqliteLogLevel = RASqliteLogLevelInfo;
#endif

/**
 Macro for sending messages to the log, depending on the level.

 @param level Level of log message.
 @param format Message format with arguments.

 @author Tobias Raatiniemi <raatiniemi@gmail.com>

 @note
 The default RASqliteLog is only used if it is not defined, hence it is possible
 to override the default logging mechanism with a custom, application specific.

 @par
 To override this macro you have to import the file with your custom macro
 within the *-Prefix.pch file. Otherwise `ifndef` will not recognize that the
 macro already have been defined.
 */
#ifndef RASqliteLog
#define RASqliteLog(level, format, ...)\
    do {\
        if ( level > _RASqliteLogLevel ) {\
            NSLog(\
                @"<%@: (%d)> %@",\
                [[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
                __LINE__,\
                [NSString stringWithFormat:(format), ##__VA_ARGS__]\
            );\
        }\
    } while(NO)
#endif

/// Shorthand logger for debug-messages.
#define RASqliteDebugLog(format, ...) \
    RASqliteLog( RASqliteLogLevelDebug, format, ##__VA_ARGS__ )

/// Shorthand logger for info-messages.
#define RASqliteInfoLog(format, ...) \
    RASqliteLog( RASqliteLogLevelInfo, format, ##__VA_ARGS__ )

/// Shorthand logger for warning-messages.
#define RASqliteWarningLog(format, ...) \
    RASqliteLog( RASqliteLogLevelWarning, format, ##__VA_ARGS__ )

/// Shorthand logger for error-messages.
#define RASqliteErrorLog(format, ...) \
    RASqliteLog( RASqliteLogLevelError, format, ##__VA_ARGS__ )

#endif /* RASqliteLog_h */
