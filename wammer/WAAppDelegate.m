//
//  WAAppDelegate.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAAppDelegate.h"
#import "IRRemoteResourcesManager.h"
#import "WAUserSelectionViewController.h"
#import "WADataStore.h"
#import "WAViewController.h"

#import "WAAuthenticationRequestViewController.h"

#import "WARemoteInterface.h"
#import "IRKeychainManager.h"

#import "WAApplicationRootViewControllerDelegate.h"

#import "UIApplication+CrashReporting.h"
#import "SetupViewController.h"

@interface WAAppDelegate () <IRRemoteResourcesManagerDelegate, WAApplicationRootViewControllerDelegate, SetupViewControllerDelegate>

// forward declarations

- (void)presentSetupViewControllerAnimated:(BOOL)animated;

@end


@implementation WAAppDelegate
@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	NSDate *launchFinishDate = [NSDate date];

	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		(id)kCFBooleanTrue, [[UIApplication sharedApplication] crashReportingEnabledUserDefaultsKey],
	nil]];
	
	[[UIApplication sharedApplication] setCrashReportRecipients:[NSArray arrayWithObjects:
		@"Evadne Wu <evadne.wu@waveface.com>",
	nil]];
	
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	self.window.backgroundColor = [UIColor blackColor];
	[self.window makeKeyAndVisible];
	
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	
	WAViewController *bottomMostViewController = [[[WAViewController alloc] init] autorelease];
	bottomMostViewController.onShouldAutorotateToInterfaceOrientation = ^ (UIInterfaceOrientation toOrientation) {
		return YES;
	};
	bottomMostViewController.onLoadview = ^ (WAViewController *self) {
		self.view = [[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 1024, 1024 }] autorelease];
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternBlackPaper"]];
	};
	
	self.window.rootViewController = bottomMostViewController;
	
	void (^initializeInterface)() = ^ {
		
		NSString *rootViewControllerClassName = nil;
		
		switch (UI_USER_INTERFACE_IDIOM()) {
			case UIUserInterfaceIdiomPad: {
				rootViewControllerClassName = @"WADiscretePaginatedArticlesViewController";
				break;
			}
			default:
			case UIUserInterfaceIdiomPhone: {
				rootViewControllerClassName = @"WAPostsViewControllerPhone";
				break;
			}
		}
		
		NSParameterAssert(rootViewControllerClassName);
		
		UIViewController *presentedViewController = [[(UIViewController *)[NSClassFromString(rootViewControllerClassName) alloc] init] autorelease];
		if ([presentedViewController conformsToProtocol:@protocol(WAApplicationRootViewController)])
			[(id<WAApplicationRootViewController>)presentedViewController setDelegate:self];
		
		BOOL needsTransition = !!self.window.rootViewController && ([[NSDate date] timeIntervalSinceDate:launchFinishDate] > 2);
		self.window.rootViewController = [[[UINavigationController alloc] initWithRootViewController:presentedViewController] autorelease];
		
		if (needsTransition) {
			
			CATransition *transition = [CATransition animation];
			transition.type = kCATransitionFade;
			transition.duration = 0.3f;
			transition.fillMode = kCAFillModeForwards;
			transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			transition.removedOnCompletion = YES;
			
			[self.window.layer addAnimation:transition forKey:kCATransition];
		
		}
		
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:needsTransition];
		
		if (![self hasAuthenticationData])
			[self presentAuthenticationRequestRemovingPriorData:YES];
    
	};
	
	
	//	UIApplication+CrashReporter shall only be used on a real device for now
	
	if ([[UIDevice currentDevice].model rangeOfString:@"Simulator"].location != NSNotFound) {
	
		initializeInterface();
	
	} else {
	
		[[UIApplication sharedApplication] handlePendingCrashReportWithCompletionBlock: ^ (BOOL didHandle) {
			if ([[UIApplication sharedApplication] crashReportingEnabled]) {
				[[UIApplication sharedApplication] enableCrashReporterWithCompletionBlock: ^ (BOOL didEnable) {
					[[UIApplication sharedApplication] setCrashReportingEnabled:didEnable];
					initializeInterface();
				}];
			} else {
				initializeInterface();
			}
		}];
	
	}

  return YES;
	
}

- (void) applicationRootViewControllerDidRequestReauthentication:(id<WAApplicationRootViewController>)controller {

	dispatch_async(dispatch_get_main_queue(), ^ {

		[self presentAuthenticationRequestRemovingPriorData:YES];
			
	});

}

- (BOOL) hasAuthenticationData {

	NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"WALastAuthenticatedUserIdentifier"];
	NSData *lastAuthenticatedUserTokenKeychainItemData = [[NSUserDefaults standardUserDefaults] dataForKey:@"WALastAuthenticatedUserTokenKeychainItem"];
	IRKeychainAbstractItem *lastAuthenticatedUserTokenKeychainItem = nil;
	
	if (!lastAuthenticatedUserTokenKeychainItem) {
		if (lastAuthenticatedUserTokenKeychainItemData) {
			lastAuthenticatedUserTokenKeychainItem = [NSKeyedUnarchiver unarchiveObjectWithData:lastAuthenticatedUserTokenKeychainItemData];
		}
	}
	
	if (lastAuthenticatedUserIdentifier)
		[WARemoteInterface sharedInterface].userIdentifier = lastAuthenticatedUserIdentifier;
	
	if (lastAuthenticatedUserTokenKeychainItem.secretString)
		[WARemoteInterface sharedInterface].userToken = lastAuthenticatedUserTokenKeychainItem.secretString;
	
	BOOL authenticationInformationSufficient = (lastAuthenticatedUserTokenKeychainItem.secretString) && lastAuthenticatedUserIdentifier;
	return authenticationInformationSufficient;

}

- (void) presentAuthenticationRequestRemovingPriorData:(BOOL)erasesExistingAuthenticationInformation {

	if (erasesExistingAuthenticationInformation) {
	
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WALastAuthenticatedUserTokenKeychainItem"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WALastAuthenticatedUserIdentifier"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"WhoAmI"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	
	}

	NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"WALastAuthenticatedUserIdentifier"];
	NSData *lastAuthenticatedUserTokenKeychainItemData = [[NSUserDefaults standardUserDefaults] dataForKey:@"WALastAuthenticatedUserTokenKeychainItem"];
	IRKeychainAbstractItem *lastAuthenticatedUserTokenKeychainItem = nil;
	
	if (!lastAuthenticatedUserTokenKeychainItem) {
		if (lastAuthenticatedUserTokenKeychainItemData) {
			lastAuthenticatedUserTokenKeychainItem = [NSKeyedUnarchiver unarchiveObjectWithData:lastAuthenticatedUserTokenKeychainItemData];
		}
	}
	
	BOOL authenticationInformationSufficient = (lastAuthenticatedUserTokenKeychainItem.secretString) && lastAuthenticatedUserIdentifier;
	
	if (!lastAuthenticatedUserTokenKeychainItem)
		lastAuthenticatedUserTokenKeychainItem = [[[IRKeychainInternetPasswordItem alloc] initWithIdentifier:@"com.waveface.wammer"] autorelease];
	
	void (^writeCredentials)(NSString *userIdentifier, NSString *userToken) = ^ (NSString *userIdentifier, NSString *userToken) {
	
		lastAuthenticatedUserTokenKeychainItem.secretString = userToken;
		[lastAuthenticatedUserTokenKeychainItem synchronize];
		
		NSData *archivedItemData = [NSKeyedArchiver archivedDataWithRootObject:lastAuthenticatedUserTokenKeychainItem];
		
		[[NSUserDefaults standardUserDefaults] setObject:archivedItemData forKey:@"WALastAuthenticatedUserTokenKeychainItem"];
		[[NSUserDefaults standardUserDefaults] setObject:userIdentifier forKey:@"WALastAuthenticatedUserIdentifier"];
		[[NSUserDefaults standardUserDefaults] setObject:userIdentifier forKey:@"WhoAmI"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[WARemoteInterface sharedInterface].userIdentifier = userIdentifier;
		[WARemoteInterface sharedInterface].userToken = userToken;
	
	};
	
	
	if (authenticationInformationSufficient) {
	
		[WARemoteInterface sharedInterface].userIdentifier = lastAuthenticatedUserIdentifier;
		[WARemoteInterface sharedInterface].userToken = lastAuthenticatedUserTokenKeychainItem.secretString;
		
		//	We don’t have to validate this again since the token never expires
	
	}
	
	if (!authenticationInformationSufficient) {
	
		__block UIViewController *userSelectionVC = [WAAuthenticationRequestViewController controllerWithCompletion: ^ (WAAuthenticationRequestViewController *self) {
		
				writeCredentials([WARemoteInterface sharedInterface].userIdentifier, [WARemoteInterface sharedInterface].userToken);
		
				[self dismissModalViewControllerAnimated:YES];
				
				void (^operations)() = ^ {
						
						CATransition *transition = [CATransition animation];
						transition.type = kCATransitionFade;
						transition.duration = 0.3f;
						transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
						transition.removedOnCompletion = YES;
						[[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:NO];
						[[UIApplication sharedApplication].keyWindow.layer addAnimation:transition forKey:@"transition"];
						
				};
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), operations);
			
		}];
		
		UINavigationController *userSelectionWrappingVC = [[[UINavigationController alloc] initWithRootViewController:userSelectionVC] autorelease];
		userSelectionWrappingVC.modalPresentationStyle = UIModalPresentationFormSheet;
        
		switch (UI_USER_INTERFACE_IDIOM()) {
		
			case UIUserInterfaceIdiomPad: {
			
				WAViewController *fullscreenBaseVC = [[[WAViewController alloc] init] autorelease];
				fullscreenBaseVC.onShouldAutorotateToInterfaceOrientation = ^ (UIInterfaceOrientation toOrientation) {
					return YES;
				};
				fullscreenBaseVC.modalPresentationStyle = UIModalPresentationFullScreen;
				fullscreenBaseVC.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternBlackPaper"]];	//	was		WAPatternCarbonFibre
				
				[fullscreenBaseVC.view addSubview:((^ {
					UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
					spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
					spinner.center = (CGPoint){
						roundf(CGRectGetMidX(fullscreenBaseVC.view.bounds)),
						roundf(CGRectGetMidY(fullscreenBaseVC.view.bounds))
					};
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
						[spinner startAnimating];							
					});
					return spinner;
				})())];
				
				[self.window.rootViewController presentModalViewController:fullscreenBaseVC animated:NO];
				[fullscreenBaseVC presentModalViewController:userSelectionWrappingVC animated:YES];
				
				break;
			
			}
			
			case UIUserInterfaceIdiomPhone:
			default: {
			
				[self.window.rootViewController presentModalViewController:userSelectionWrappingVC animated:NO];
				break;
				
			}
		
		}
	
	}

}

#pragma mark -- Setup View Controller and Delegate

- (void) applicationRootViewControllerDidRequestChangeAPIURL:(id<WAApplicationRootViewController>)controller
{
  [self presentSetupViewControllerAnimated:YES];
}

- (void)presentSetupViewControllerAnimated:(BOOL)animated
// Presents the setup view controller.
{
  __block SetupViewController *vc;
  
  vc = [[[SetupViewController alloc] initWithAPIURLString:[[NSUserDefaults standardUserDefaults] stringForKey:@"APIURLString"]] autorelease];
  assert(vc != nil);
  
  vc.delegate = self;
  
  [vc presentModallyOn:self.window.rootViewController animated:animated];
}

- (void)setupViewController:(SetupViewController *)controller didChooseString:(NSString *)string{
  assert(controller != nil);
  assert(string != nil);
  
  [[NSUserDefaults standardUserDefaults] setObject:string forKey:@"APIURLString"];
  [[NSUserDefaults standardUserDefaults] synchronize];

  // TODO update remote interface context here. Right now the API update only works when the app is killed and restarted.
  [controller dismissModalViewControllerAnimated:YES];
}

- (void)setupViewControllerDidCancel:(SetupViewController *)controller{
  [controller dismissModalViewControllerAnimated:YES];
}

#pragma mark -- Network Activity

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
