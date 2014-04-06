//
//  RASqliteIndex.h
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2014-02-04.
//  Copyright (c) 2013-2014 Raatiniemi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RASqliteIndex : NSObject {
@protected
	BOOL _unique;
}

@property (atomic, getter = isUnique) BOOL unique;

@end