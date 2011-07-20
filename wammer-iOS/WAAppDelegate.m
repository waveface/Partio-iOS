//
//  WAAppDelegate.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAppDelegate.h"

@implementation WAAppDelegate

@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[[UINavigationController alloc] initWithRootViewController:[[(UIViewController *)[NSClassFromString(@"WAArticleViewController") alloc] init] autorelease]] autorelease];
	
	[self.window makeKeyAndVisible];
	
	return YES;
	
}

@end
