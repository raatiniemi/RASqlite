//
//  RAAppDelegate.m
//  RASqlite
//
//  Created by Tobias Raatiniemi on 2013-07-27.
//  Copyright (c) 2013 The Developer Blog. All rights reserved.
//

#import "RAAppDelegate.h"

@implementation RAAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	[self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
	[[self window] setBackgroundColor:[UIColor whiteColor]];
	[[self window] makeKeyAndVisible];
}

@end