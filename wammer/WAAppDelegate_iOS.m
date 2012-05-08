//
//  WAAppDelegate_iOS.m
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAAppDelegate_iOS.h"

#import <AVFoundation/AVFoundation.h>

#import "WADefines.h"

#import "WAAppDelegate.h"

#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WANavigationController.h"

#import "WAAuthenticationRequestViewController.h"
#import "WARegisterRequestViewController.h"

#import "WARemoteInterface.h"

#import "WAApplicationRootViewControllerDelegate.h"

#import "WANavigationBar.h"

#import "UIView+IRAdditions.h"

#import "IRAlertView.h"
#import "IRAction.h"

#import "WAOverviewController.h"
#import "WATimelineViewControllerPhone.h"
#import "WAUserInfoViewController.h"

#import "WAStationDiscoveryFeedbackViewController.h"

#import "IRLifetimeHelper.h"
#import "WAOverlayBezel.h"

#import "UIWindow+IRAdditions.h"

#import "IASKSettingsReader.h"

#import	"DCIntrospect.h"
#import "UIKit+IRAdditions.h"

#import "WARegisterRequestViewController+SubclassEyesOnly.h"


@interface WAAppDelegate_iOS () <WAApplicationRootViewControllerDelegate>

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification;
- (void) handleObservedRemoteURLNotification:(NSNotification *)aNotification;
- (void) handleIASKSettingsChanged:(NSNotification *)aNotification;
- (void) handleIASKSettingsDidRequestAction:(NSNotification *)aNotification;

@property (nonatomic, readwrite, assign) BOOL alreadyRequestingAuthentication;

- (void) clearViewHierarchy;
- (void) recreateViewHierarchy;
- (void) handleDebugModeToggled;

- (void) handleAuthRequest:(NSString *)reason withOptions:(NSDictionary *)options completion:(void(^)(BOOL didFinish, NSError *error))block;
- (BOOL) isRunningAuthRequest;

@end


@implementation WAAppDelegate_iOS
@synthesize window = _window;
@synthesize alreadyRequestingAuthentication;

- (void) bootstrap {
	
	[super bootstrap];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleObservedAuthenticationFailure:) name:kWARemoteInterfaceDidObserveAuthenticationFailureNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleObservedRemoteURLNotification:) name:kWAApplicationDidReceiveRemoteURLNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIASKSettingsChanged:) name:kIASKAppSettingChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIASKSettingsDidRequestAction:) name:kWASettingsDidRequestActionNotification object:nil];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[WARemoteInterface sharedInterface].apiKey = kWARemoteEndpointApplicationKeyPad;
	else {
		[WARemoteInterface sharedInterface].apiKey = kWARemoteEndpointApplicationKeyPhone;
	}

	if (!WAApplicationHasDebuggerAttached()) {
	
		WF_TESTFLIGHT(^ {
		
			[TestFlight setOptions:[NSDictionary dictionaryWithObjectsAndKeys:
				(id)kCFBooleanFalse, @"sendLogOnlyOnCrash",
			nil]];
			
			[TestFlight takeOff:kWATestflightTeamToken];
			
			id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kWAAppEventNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
				
				NSString *eventTitle = [[note userInfo] objectForKey:kWAAppEventTitle];
				[TestFlight passCheckpoint:eventTitle];
				
			}];
			
			objc_setAssociatedObject([TestFlight class], &kWAAppEventNotification, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		});
		
		WF_CRASHLYTICS(^ {
			
			[Crashlytics startWithAPIKey:@"d79b0f823e42fdf1cdeb7e988a8453032fd85169"];
			[Crashlytics sharedInstance].debugMode = YES;
			
		});
	
		WF_GOOGLEANALYTICS(^ {
		
			[[GANTracker sharedTracker] startTrackerWithAccountID:kWAGoogleAnalyticsAccountID dispatchPeriod:kWAGoogleAnalyticsDispatchInterval delegate:nil];
			[GANTracker sharedTracker].debug = YES;
			
			id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kWAAppEventNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
				
				[[GANTracker sharedTracker] 
					trackEvent: [[note userInfo] objectForKey:@"category"]
					action:	[[note userInfo] objectForKey:@"action"]
					label:	[[note userInfo] objectForKey:@"label"]
					value:	(NSInteger)[[note userInfo] objectForKey:@"value"]
					withError:nil];
				
			}];
			
			objc_setAssociatedObject([GANTracker class], &kWAAppEventNotification, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		});
		
	}
		
	AVAudioSession * const audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
	[audioSession setActive:YES error:nil];
	
	WADefaultBarButtonInitialize();
	
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	[self bootstrap];
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor blackColor];
	[self.window makeKeyAndVisible];
	
	if ([[NSUserDefaults standardUserDefaults] stringForKey:kWADebugPersistentStoreName]) {
	
		NSString *identifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWADebugPersistentStoreName];
		[self bootstrapPersistentStoreWithUserIdentifier:identifier];
		
		[self recreateViewHierarchy];
	
	} else if (![self hasAuthenticationData]) {
	
		[self applicationRootViewControllerDidRequestReauthentication:nil];
					
	} else {
	
		NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserIdentifier];
		
		if (lastAuthenticatedUserIdentifier)
			[self bootstrapPersistentStoreWithUserIdentifier:lastAuthenticatedUserIdentifier];
		
		[self recreateViewHierarchy];
		
	}

	WAPostAppEvent(@"AppVisit", [NSDictionary dictionaryWithObjectsAndKeys:@"app",@"category",@"visit", @"action", nil]);

  return YES;
	
}

- (void) clearViewHierarchy {

	UIViewController *rootVC = self.window.rootViewController;
	
	__block void (^zapModal)(UIViewController *) = [^ (UIViewController *aVC) {
	
		if (aVC.presentedViewController)
			zapModal(aVC.presentedViewController);
		
		[aVC dismissViewControllerAnimated:NO completion:nil];
	
	} copy];
	
	zapModal(rootVC);
	
	
	IRViewController *emptyVC = [[IRViewController alloc] init];
	__weak IRViewController *wEmptyVC = emptyVC;
	
	emptyVC.onShouldAutorotateToInterfaceOrientation = ^ (UIInterfaceOrientation toOrientation) {
		
		return YES;
		
	};
	
	emptyVC.onLoadView = ^ {
	
		wEmptyVC.view = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 1024, 1024 }];
		wEmptyVC.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternBlackPaper"]];
		
	};
	
	self.window.rootViewController = emptyVC;
	
	[rootVC didReceiveMemoryWarning];
	
}

- (void) recreateViewHierarchy {

	[[IRRemoteResourcesManager sharedManager].queue cancelAllOperations];
	
	switch (UI_USER_INTERFACE_IDIOM()) {
	
		case UIUserInterfaceIdiomPad: {
		
			WAOverviewController *presentedViewController = [[WAOverviewController alloc] init];
			WANavigationController *rootNavC = [[WANavigationController alloc] initWithRootViewController:presentedViewController];
			
			[presentedViewController setDelegate:self];
			
			self.window.rootViewController = rootNavC;
		
			break;
		
		}
		
		case UIUserInterfaceIdiomPhone: {
			
			WATimelineViewControllerPhone *timelineVC = [[WATimelineViewControllerPhone alloc] init];
			WANavigationController *timelineNavC = [[WANavigationController alloc] initWithRootViewController:timelineVC];
			
			[timelineVC setDelegate:self];
						
			self.window.rootViewController = timelineNavC;
		
			break;
		
		}
	
	}
	
//	NSString *rootViewControllerClassName = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ?
//		@"WAOverviewController" :
//		@"WATimelineViewControllerPhone";
//	
//	NSParameterAssert(rootViewControllerClassName);
//	
//	UIViewController *presentedViewController = [(UIViewController *)[NSClassFromString(rootViewControllerClassName) alloc] init];
//	self.window.rootViewController = [[WANavigationController alloc] initWithRootViewController:presentedViewController];
//		
//	if ([presentedViewController conformsToProtocol:@protocol(WAApplicationRootViewController)])
//		[(id<WAApplicationRootViewController>)presentedViewController setDelegate:self];
			
}





- (void) applicationRootViewControllerDidRequestReauthentication:(id<WAApplicationRootViewController>)controller {

	dispatch_async(dispatch_get_main_queue(), ^ {

		[self presentAuthenticationRequestWithReason:nil allowingCancellation:NO removingPriorData:YES clearingNavigationHierarchy:YES onAuthSuccess:^(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
		
			[self updateCurrentCredentialsWithUserIdentifier:userIdentifier token:userToken primaryGroup:primaryGroupIdentifier];
			[self bootstrapPersistentStoreWithUserIdentifier:userIdentifier];
			
		} runningOnboardingProcess:YES];
		
	});

}

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification {

	NSError *error = [[aNotification userInfo] objectForKey:@"error"];

  dispatch_async(dispatch_get_main_queue(), ^{

		[self presentAuthenticationRequestWithReason:[error localizedDescription] allowingCancellation:YES removingPriorData:NO clearingNavigationHierarchy:NO onAuthSuccess:^(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
			
			[self updateCurrentCredentialsWithUserIdentifier:userIdentifier token:userToken primaryGroup:primaryGroupIdentifier];
			[self bootstrapPersistentStoreWithUserIdentifier:userIdentifier];
			
		} runningOnboardingProcess:NO];

  });
  
}

- (void) handleObservedRemoteURLNotification:(NSNotification *)aNotification {
	
	NSString *command = nil;
	NSDictionary *params = nil;
	
	if (!WAIsXCallbackURL([[aNotification userInfo] objectForKey:@"url"], &command, &params))
		return;
	
	if ([command isEqualToString:kWACallbackActionSetAdvancedFeaturesEnabled]) {
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:kWAAdvancedFeaturesEnabled])
			return;
		
		[defaults setBool:YES forKey:kWAAdvancedFeaturesEnabled];
		
		if (![defaults synchronize])
			return;
		
		[self handleDebugModeToggled];
		
		return;
		
	}
	
	if ([command isEqualToString:kWACallbackActionSetRemoteEndpointURL]) {
		
		__block __typeof__(self) nrSelf = self;
		void (^zapAndRequestReauthentication)() = ^ {

			[[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"url"] forKey:kWARemoteEndpointURL];
			[[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"RegistrationUrl"] forKey:kWAUserRegistrationEndpointURL];
			[[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"PasswordResetUrl"] forKey:kWAUserPasswordResetEndpointURL];
			[[NSUserDefaults standardUserDefaults] synchronize];

			if (nrSelf.alreadyRequestingAuthentication) {
				nrSelf.alreadyRequestingAuthentication = NO;
				[nrSelf clearViewHierarchy];
			}
			
			[nrSelf applicationRootViewControllerDidRequestReauthentication:nil];
			
		};
		
		NSString *alertTitle = @"Switch endpoint to";
		NSString *alertText = [params objectForKey:@"url"];
		
		IRAction *cancelAction = [IRAction actionWithTitle:@"Cancel" block:nil];
		IRAction *confirmAction = [IRAction actionWithTitle:@"Yes, Switch" block:zapAndRequestReauthentication];
		
		[[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:
			confirmAction,
		nil]] show];
	}
	
}

- (void) handleIASKSettingsChanged:(NSNotification *)aNotification {

	if ([[[aNotification userInfo] allKeys] containsObject:kWAAdvancedFeaturesEnabled])
		[self handleDebugModeToggled];

}

- (void) handleIASKSettingsDidRequestAction:(NSNotification *)aNotification {

	NSString *action = [[aNotification userInfo] objectForKey:@"key"];
	
	if ([action isEqualToString:@"WASettingsActionResetDefaults"]) {
	
		__weak WAAppDelegate_iOS *wSelf = self;
		
		NSString *alertTitle = NSLocalizedString(@"RESET_SETTINGS_CONFIRMATION_TITLE", nil);
		NSString *alertText = NSLocalizedString(@"RESET_SETTINGS_CONFIRMATION_DESCRIPTION", nil);
	
		IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
		IRAction *resetAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_RESET", nil) block: ^ {
		
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
			for (NSString *key in [[defaults dictionaryRepresentation] allKeys])
				[defaults removeObjectForKey:key];
				
			[defaults synchronize];
			
			[wSelf clearViewHierarchy];
			[wSelf recreateViewHierarchy];
		
		}];
		
		IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:
			
			resetAction,
			
		nil]];
		
		[alertView show];
	
	}

}

- (void) handleDebugModeToggled {

	__weak WAAppDelegate_iOS *wSelf = self;
	
	BOOL isNowEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kWAAdvancedFeaturesEnabled];
	
	NSString *alertTitle;
	NSString *alertText;
	IRAlertView *alertView = nil;
	
	void (^zapAndRequestReauthentication)() = ^ {
	
		if (self.alreadyRequestingAuthentication) {
			wSelf.alreadyRequestingAuthentication = NO;
			[wSelf clearViewHierarchy];
		}
		
		[wSelf applicationRootViewControllerDidRequestReauthentication:nil];
		
	};
	
	if (isNowEnabled) {
		alertTitle = NSLocalizedString(@"ADVANCED_FEATURES_ENABLED_TITLE", nil);
		alertText = NSLocalizedString(@"ADVANCED_FEATURES_ENABLED_DESCRIPTION", nil);
	} else {
		alertTitle = NSLocalizedString(@"ADVANCED_FEATURES_DISABLED_TITLE", nil);
		alertText = NSLocalizedString(@"ADVANCED_FEATURES_DISABLED_DESCRIPTION", nil);
	}

	IRAction *okayAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_OKAY", nil) block:nil];
	IRAction *okayAndZapAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_OKAY", nil) block:zapAndRequestReauthentication];
	IRAction *laterAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_LATER", nil) block:nil];
	IRAction *signOutAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) block:zapAndRequestReauthentication];
	
	if (self.alreadyRequestingAuthentication) {
		
		//	User is not authenticated, and also we’re already at the auth view
		//	Can zap
		
		alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:nil otherActions:[NSArray arrayWithObjects:
			okayAndZapAction,
		nil]];
	
	} else if (![self hasAuthenticationData]) {
	
		//	In the middle of an active auth session, not safe to zap
		
		alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:okayAction otherActions:nil];
	
	} else {
	
		//	Can zap
	
		alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:laterAction otherActions:[NSArray arrayWithObjects:
			signOutAction,
		nil]];
	
	}
	
	[alertView show];

}

- (BOOL) presentAuthenticationRequestWithReason:(NSString *)aReason allowingCancellation:(BOOL)allowsCancellation removingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything onAuthSuccess:(void (^)(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier))successBlock runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged {

	if ([self isRunningAuthRequest])
		return NO;
	
  if (allowsCancellation)
    NSParameterAssert(!eraseAuthInfo);

	if (eraseAuthInfo)
    [self removeAuthenticationData];
	
	if (zapEverything)
		[self clearViewHierarchy];
	
	[self handleAuthRequest:aReason withOptions:nil completion:^(BOOL didFinish, NSError *error) {
	
		WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	
		if (didFinish)
			if (successBlock)
				successBlock(ri.userIdentifier, ri.userToken, ri.primaryGroupIdentifier);
		
	}];
	
	return YES;

}

- (void) handleAuthRequest:(NSString *)reason withOptions:(NSDictionary *)options completion:(void(^)(BOOL didFinish, NSError *error))block {

	__weak WAAppDelegate_iOS *wAppDelegate = self;

	NSParameterAssert(!self.alreadyRequestingAuthentication);
	self.alreadyRequestingAuthentication = YES;

  NSString *lastUserID = [WARemoteInterface sharedInterface].userIdentifier;
  BOOL (^userIDChanged)() = ^ {
		
		NSString *currentID = [WARemoteInterface sharedInterface].userIdentifier;
    return (BOOL)![currentID isEqualToString:lastUserID];
		
  };
	
	void (^handleAuthSuccess)(void) = ^ {
	
		if (block)
			block(YES, nil);
			
		wAppDelegate.alreadyRequestingAuthentication = NO;
		
	};
	
  WAAuthenticationRequestViewController *authRequestVC = [WAAuthenticationRequestViewController controllerWithCompletion: ^ (WAAuthenticationRequestViewController *self, NSError *anError) {
  
		if (anError) {
			[self presentError:anError completion:nil];
			return;
		}

		if (userIDChanged()) {
		
			UINavigationController *navC = self.navigationController;
			[wAppDelegate clearViewHierarchy];
			
			handleAuthSuccess();
			
			[wAppDelegate recreateViewHierarchy];
			[wAppDelegate.window.rootViewController presentViewController:navC animated:NO completion:nil];

		} else {
		
			handleAuthSuccess();
			
		}

		[self dismissViewControllerAnimated:YES completion:nil];
		
  }];
	
	authRequestVC.navigationItem.prompt = reason;
  
	WANavigationController *authRequestWrappingVC = [[WANavigationController alloc] initWithRootViewController:authRequestVC];
	authRequestWrappingVC.modalPresentationStyle = UIModalPresentationFormSheet;
	authRequestWrappingVC.disablesAutomaticKeyboardDismissal = NO;

	[self.window.rootViewController presentViewController:authRequestWrappingVC animated:NO completion:nil];

}

- (BOOL) isRunningAuthRequest {

	return self.alreadyRequestingAuthentication;

}

static unsigned int networkActivityStackingCount = 0;

- (void) beginNetworkActivity {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self beginNetworkActivity];
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
			[self endNetworkActivity];
		});
		return;
	}

	NSParameterAssert(networkActivityStackingCount > 0);
	networkActivityStackingCount--;
	
	if (networkActivityStackingCount == 0)
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

  [[NSNotificationCenter defaultCenter] postNotificationName:kWAApplicationDidReceiveRemoteURLNotification object:url userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
  
    url, @"url",
    sourceApplication, @"sourceApplication",
    annotation, @"annotation",
  
  nil]];

  return YES;

}

- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {

	WAPostAppEvent(@"did-receive-memory-warning", [NSDictionary dictionaryWithObjectsAndKeys:
	
		//	TBD
	
	nil]);

}

@end
