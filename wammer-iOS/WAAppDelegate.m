//
//  WAAppDelegate.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAppDelegate.h"
#import "IRRemoteResourcesManager.h"

@interface WAAppDelegate () <IRRemoteResourcesManagerDelegate>
@end


@implementation WAAppDelegate
@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	NSString *rootViewControllerClassName = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? @"WAArticlesViewController_iPhone" : @"WAArticlesViewController";
	self.window.rootViewController = [[[UINavigationController alloc] initWithRootViewController:[[(UIViewController *)[NSClassFromString(rootViewControllerClassName) alloc] init] autorelease]] autorelease];
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
                                dictionaryWithObject:@"fc3a9ff8bc0a11e0b3b7c82b" forKey:@"WhoAmI"];
        
    [defaults registerDefaults:appDefaults];
    NSLog(@"%@", defaults);
    
	[self.window makeKeyAndVisible];
	
	return YES;
	
}

static unsigned int networkActivityStackingCount = 0;

- (void) beginNetworkActivity {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}
	
	networkActivityStackingCount++;
	
	if (networkActivityStackingCount > 0)
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

}

- (void) endNetworkActivity {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}

	NSParameterAssert(networkActivityStackingCount > 0);
	networkActivityStackingCount--;
	
	if (networkActivityStackingCount == 0)
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

}

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didBeginDownloadingResourceAtURL:(NSURL *)anURL {

	[self beginNetworkActivity];

}

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFinishDownloadingResourceAtURL:(NSURL *)anURL {

	[self endNetworkActivity];

}
- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFailDownloadingResourceAtURL:(NSURL *)anURL {

	[self endNetworkActivity];

}

@end
