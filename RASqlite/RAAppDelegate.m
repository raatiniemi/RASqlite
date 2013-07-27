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

	RAUserListViewController *userList = [[RAUserListViewController alloc] init];
	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:userList];
	[[self window] setRootViewController:navigation];

	[[self window] makeKeyAndVisible];
}

@end