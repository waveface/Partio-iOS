//
//  WAAppDelegate.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAppDelegate.h"
#import "IRRemoteResourcesManager.h"
#import "WAUserSelectionViewController.h"
#import "WADataStore.h"
#import "WAViewController.h"

@interface WAAppDelegate () <IRRemoteResourcesManagerDelegate>
@end


@implementation WAAppDelegate
@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	
	NSString *rootViewControllerClassName = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? @"WAPostsViewControllerPhone" : @"WAArticlesViewController";
	self.window.rootViewController = [[[UINavigationController alloc] initWithRootViewController:[[(UIViewController *)[NSClassFromString(rootViewControllerClassName) alloc] init] autorelease]] autorelease];
	
	[self.window makeKeyAndVisible];
	
	NSString *currentUserIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"WhoAmI"];
	
	if (!currentUserIdentifier) {
        
        // setup user selection view controller
        __block WAUserSelectionViewController *userSelectionVC;
        userSelectionVC = [WAUserSelectionViewController controllerWithElectibleUsers:nil onSelection:^(NSURL *pickedUser) {
            
            NSManagedObjectContext *disposableContext = [[WADataStore defaultStore] disposableMOC];
            WAUser *userObject = (WAUser *)[disposableContext irManagedObjectForURI:pickedUser];
            NSString *userIdentifier = userObject.identifier;
            
            [[NSUserDefaults  standardUserDefaults] setObject:userIdentifier forKey:@"WhoAmI"];
            [[NSUserDefaults  standardUserDefaults] synchronize];
            
            [userSelectionVC.navigationController dismissModalViewControllerAnimated:YES];
            
            void (^operations)() = ^ {
                
                CATransition *transition = [CATransition animation];
                transition.type = kCATransitionFade;
                transition.duration = 0.3f;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                transition.removedOnCompletion = YES;
                [self.window.rootViewController dismissModalViewControllerAnimated:NO];
                [self.window.layer addAnimation:transition forKey:@"transition"];
                
            };
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), operations);
            
        }];
        
        UINavigationController *userSelectionWrappingVC = [[[UINavigationController alloc] initWithRootViewController:userSelectionVC] autorelease];
        userSelectionWrappingVC.modalPresentationStyle = UIModalPresentationFormSheet;
        
		switch (UI_USER_INTERFACE_IDIOM()) {
		
			case UIUserInterfaceIdiomPad: {
                // show a beautiful background on iPad
			
				WAViewController *fullscreenBaseVC = [[[WAViewController alloc] init] autorelease];
				fullscreenBaseVC.onShouldAutorotateToInterfaceOrientation = ^ (UIInterfaceOrientation toOrientation) {
					return YES;
				};
				fullscreenBaseVC.modalPresentationStyle = UIModalPresentationFullScreen;
				[fullscreenBaseVC.view addSubview:((^ {
					
					UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
					spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
					spinner.center = (CGPoint){
						roundf(CGRectGetMidX(fullscreenBaseVC.view.bounds)),
						roundf(CGRectGetMidY(fullscreenBaseVC.view.bounds))
					};
					[spinner startAnimating];
					return spinner;
					
				})())];
				fullscreenBaseVC.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternCarbonFibre"]];
				[self.window.rootViewController presentModalViewController:fullscreenBaseVC animated:NO];
				[fullscreenBaseVC presentModalViewController:userSelectionWrappingVC animated:YES];
			
				break;
			
			}
			
			case UIUserInterfaceIdiomPhone:
			default: {
                // no background
                
                [self.window.rootViewController presentModalViewController:userSelectionWrappingVC animated:NO];
			
				break;
			
			}
		
		}
	
	}
		
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
