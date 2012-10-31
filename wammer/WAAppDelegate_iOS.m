//
//  WAAppDelegate_iOS.m
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "WAAppDelegate_iOS.h"

#import "WADefines.h"
#import "WAAppDelegate.h"

#import "WAAppearance.h"

#import "WARemoteInterface.h"
#import "WARemoteInterface+WebSocket.h"
#import "WARemoteInterface+RemoteNotifications.h"
#import "WASyncManager.h"

#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WANavigationController.h"
#import "WAApplicationRootViewControllerDelegate.h"
#import "WAOverviewController.h"
#import "WATimelineViewControllerPhone.h"
#import "WAUserInfoViewController.h"
#import "WAOverlayBezel.h"

#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"

#import "IRSlidingSplitViewController.h"
#import "WASlidingSplitViewController.h"

#import "IASKSettingsReader.h"
#import	"DCIntrospect.h"

#import <FacebookSDK/FacebookSDK.h>

#import "WAWelcomeViewController.h"
#import "WATutorialViewController.h"

#import "IIViewDeckController.h"
#import "WASlidingMenuViewController.h"
#import "WADayViewController.h"

#if ENABLE_PONYDEBUG
	#import "PonyDebugger/PDDebugger.h"
#endif

#import "WAFilterPickerViewController.h"
#import "WAPhotoImportManager.h"
#import "WAFirstUseViewController.h"

#import "TestFlight.h"

static NSString *const kTrackingId = @"UA-27817516-7";

@interface WALoginBackgroundViewController : UIViewController
@end

@implementation WALoginBackgroundViewController

- (UIColor *)decoratedBackgroundColor: (UIInterfaceOrientation) currentInterfaceOrientation {
	if (UIInterfaceOrientationIsPortrait(currentInterfaceOrientation) ||
			currentInterfaceOrientation == 0)
		return [UIColor colorWithPatternImage:[UIImage imageNamed:@"LoginBackground-Portrait"]];
	else
		return [UIColor colorWithPatternImage:[UIImage imageNamed:@"LoginBackground-Landscape"]];

}

- (void)viewDidLoad {
	self.view.backgroundColor = [self decoratedBackgroundColor:[[UIDevice currentDevice] orientation]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	self.view.backgroundColor = [self decoratedBackgroundColor:toInterfaceOrientation];
}

@end

@interface WAAppDelegate_iOS () <WAApplicationRootViewControllerDelegate, WACacheManagerDelegate>

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification;
- (void) handleObservedRemoteURLNotification:(NSNotification *)aNotification;
- (void) handleIASKSettingsChanged:(NSNotification *)aNotification;
- (void) handleIASKSettingsDidRequestAction:(NSNotification *)aNotification;

@property (nonatomic, readwrite, assign) BOOL alreadyRequestingAuthentication;
@property (nonatomic, readwrite) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic, readwrite, strong) WAPhotoImportManager *photoImportManager;

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
			
			[Crashlytics startWithAPIKey:kWACrashlyticsAPIKey];
			[Crashlytics sharedInstance].debugMode = YES;
			
		});
		
	}
	
	AVAudioSession * const audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
	[audioSession setActive:YES error:nil];
	
	WADefaultBarButtonInitialize();
	
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	[self bootstrap];
	
	WADefaultAppearance();
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor colorWithRed:0.87 green:0.87 blue:0.84 alpha:1.0];
	
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

//	[GAI sharedInstance].debug = YES;
	[GAI sharedInstance].dispatchInterval = 120;
	[GAI sharedInstance].trackUncaughtExceptions = YES;
	self.tracker = [[GAI sharedInstance] trackerWithTrackingId:kTrackingId];
	
	[self.tracker trackEventWithCategory:@"Application:didFinishLaunchingWithOptions:"
														withAction:@"App Launched"
														 withLabel:nil
														 withValue:@-1];
	
	[[WARemoteInterface sharedInterface] enableAutomaticRemoteUpdatesTimer];
	[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kWAFilterPickerViewSelectedRowIndex];
	
#if ENABLE_PONYDEBUG
	PDDebugger *debugger = [PDDebugger defaultInstance];
	[debugger connectToURL:[NSURL URLWithString:@"ws://localhost:9000/device"]];
	[debugger enableNetworkTrafficDebugging];
	[debugger forwardAllNetworkTraffic];
	
	WADataStore * const ds = [WADataStore defaultStore];
	NSManagedObjectContext *context = [ds disposableMOC];
	[debugger enableCoreDataDebugging];
	[debugger addManagedObjectContext:context withName:@"My MOC"];
#endif

#if ENABLE_DCINTROSPECT
	[[DCIntrospect sharedIntrospector] start];
#endif
	
	[TestFlight takeOff:kWATestflightTeamToken];

#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	[TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#pragma clang pop
#endif
	
	return YES;
	
}

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	NSString * kMSG_NOTIFICATION_PHOTOS_IMPORTED = NSLocalizedString(@"NOTIFY_PHOTOS_IMPORTED", @"Notification messages for photos auto-imported");
	NSString * kMSG_NOTIFICATION_TESTING = NSLocalizedString(@"NOTIFY_TESTING", @"For remote notification testing");
#pragma unused(kMSG_NOTIFICATION_PHOTOS_IMPORTED)
#pragma unused(kMSG_NOTIFICATION_TESTING)
	
	NSString* deviceTokenString = [[[[deviceToken description]
																	 stringByReplacingOccurrencesOfString: @"<" withString: @""]
																	stringByReplacingOccurrencesOfString: @">" withString: @""]
																 stringByReplacingOccurrencesOfString: @" " withString: @""];

	NSLog(@"device token in data: %@", deviceToken);
	NSLog(@"device token : %@", deviceTokenString);

	[[WARemoteInterface sharedInterface] subscribeRemoteNotificationForDevtoken:deviceTokenString onSuccess:nil onFailure:nil];

}

- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

	NSLog(@"Fail to register for remote notification with error: %@", error);

}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	
	
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

	__weak WAAppDelegate_iOS *wSelf = self;
	self.bgTask = [application beginBackgroundTaskWithExpirationHandler:^{

		NSLog(@"Background photo import expired");
		[application endBackgroundTask:wSelf.bgTask];
		wSelf.bgTask = UIBackgroundTaskInvalid;

	}];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

		NSLog(@"Enter background, wait until photo import operations finished");
		[wSelf.photoImportManager waitUntilFinished];
		NSLog(@"All photo import operations are finished");
		[application endBackgroundTask:wSelf.bgTask];
		wSelf.bgTask = UIBackgroundTaskInvalid;

	});

}

- (void) subscribeRemoteNotification {
	
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];
	
}

- (void) unsubscribeRemoteNotification {
	
	[[UIApplication sharedApplication] unregisterForRemoteNotifications];

}

- (void) clearViewHierarchy {
	
	UIViewController *rootVC = self.window.rootViewController;
	
	__block void (^zapModal)(UIViewController *) = [^ (UIViewController *aVC) {
		
		if (aVC.presentedViewController)
			zapModal(aVC.presentedViewController);
		
		[aVC dismissViewControllerAnimated:NO completion:nil];
		// WASlidingSplitViewController
		
	} copy];
	
	zapModal(rootVC);

	self.window.rootViewController = [[WALoginBackgroundViewController alloc] init];
	
}

- (void) recreateViewHierarchy {

	[[IRRemoteResourcesManager sharedManager].queue cancelAllOperations];
	
	switch (UI_USER_INTERFACE_IDIOM()) {
	
		case UIUserInterfaceIdiomPad: {
		
			IRSlidingSplitViewController *ssVC = [WASlidingSplitViewController new];
		
			WAOverviewController *presentedViewController = [[WAOverviewController alloc] init];
			WANavigationController *rootNavC = [[WANavigationController alloc] initWithRootViewController:presentedViewController];
			
			[presentedViewController setDelegate:self];
			
			ssVC.masterViewController = rootNavC;
			
			self.window.rootViewController = ssVC;
		
			break;
		
		}
		
		case UIUserInterfaceIdiomPhone: {
			
//			WATimelineViewControllerPhone *timelineVC = [[WATimelineViewControllerPhone alloc] init];
			WADayViewController *swVC = [[WADayViewController alloc] init];

			WANavigationController *timelineNavC = [[WANavigationController alloc] initWithRootViewController:swVC];
			
		//	[timelineVC setDelegate:self];
			
			WASlidingMenuViewController *slidingMenu = [[WASlidingMenuViewController alloc] init];
			slidingMenu.delegate = self;

			IIViewDeckController *viewDeckController = [[IIViewDeckController alloc] initWithCenterViewController:timelineNavC leftViewController:slidingMenu];
			viewDeckController.view.backgroundColor = [UIColor blackColor];
			viewDeckController.leftLedge = self.window.frame.size.width - 200.0f;
			viewDeckController.rotationBehavior = IIViewDeckRotationKeepsLedgeSizes;
			viewDeckController.animationBehavior = IIViewDeckAnimationPullIn;
			viewDeckController.panningMode = IIViewDeckNoPanning;
			[viewDeckController setWantsFullScreenLayout:YES];
			viewDeckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
	
			self.window.rootViewController = viewDeckController;
		
			break;
		
		}
	
	}
	
	UIViewController *vc = self.window.rootViewController;
	
	[vc willRotateToInterfaceOrientation:vc.interfaceOrientation duration:0];
	[vc willAnimateRotationToInterfaceOrientation:vc.interfaceOrientation duration:0];
	[vc didRotateFromInterfaceOrientation:vc.interfaceOrientation];

			
}

- (void) logout {

	self.photoImportManager = nil;
	self.cacheManager = nil;

	BOOL const WAPhotoImportEnabledDefault = NO;

	[[NSUserDefaults standardUserDefaults] setBool:WAPhotoImportEnabledDefault forKey:kWAPhotoImportEnabled];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[self unsubscribeRemoteNotification];

}

- (void) applicationRootViewControllerDidRequestReauthentication:(id<WAApplicationRootViewController>)controller {

	[self logout];

	__weak WAAppDelegate_iOS *wSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^ {

		[wSelf presentAuthenticationRequestWithReason:nil
														allowingCancellation:NO
															 removingPriorData:YES
										 clearingNavigationHierarchy:YES
																	 onAuthSuccess:
		 ^(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
			 [wSelf updateCurrentCredentialsWithUserIdentifier:userIdentifier
																								 token:userToken
																					primaryGroup:primaryGroupIdentifier];
			 // bind to user's persistent store
			 [wSelf bootstrapPersistentStoreWithUserIdentifier:userIdentifier];

			 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

				 if (!wSelf.photoImportManager) {
					 wSelf.photoImportManager = [[WAPhotoImportManager alloc] init];
				 }
				 if (wSelf.photoImportManager.enabled) {
					 [wSelf.photoImportManager createPhotoImportArticlesWithCompletionBlock:^{
						 NSLog(@"All photo import operations are enqueued");
					 }];
				 }

				 if (!wSelf.cacheManager) {
					 wSelf.cacheManager = [[WACacheManager alloc] init];
					 wSelf.cacheManager.delegate = self;
				 }
				 [wSelf.cacheManager clearPurgeableFilesIfNeeded];

				 // reset monitored hosts
				 WARemoteInterface *ri = [WARemoteInterface sharedInterface];

				 // close websocket if needed
				 [ri closeWebSocketConnection];

				 ri.monitoredHosts = nil;
				 [ri performAutomaticRemoteUpdatesNow];

				 // reset pending original objects
				 [[WASyncManager sharedManager] reload];

			 });
		 }
												runningOnboardingProcess:YES];
		
	});

}

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification {

	NSError *error = [[aNotification userInfo] objectForKey:@"error"];
	
	[self unsubscribeRemoteNotification];

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
			[[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"FacebookAuthUrl"] forKey:kWAUserFacebookAuthenticationEndpointURL];
			[[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"FacebookAppID"] forKey:kWAFacebookAppID];
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

- (BOOL) presentAuthenticationRequestWithReason:(NSString *)aReason
													 allowingCancellation:(BOOL)allowsCancellation
															removingPriorData:(BOOL)eraseAuthInfo
										clearingNavigationHierarchy:(BOOL)zapEverything
																	onAuthSuccess:(void (^)(NSString *userIdentifier,
																													NSString *userToken,
																													NSString *primaryGroupIdentifier))successBlock
											 runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged {

	if ([self isRunningAuthRequest])
		return NO;
	
  if (allowsCancellation)
    NSParameterAssert(!eraseAuthInfo);

	if (eraseAuthInfo)
    [self removeAuthenticationData];
	
	if (zapEverything)
		[self clearViewHierarchy];
	
	[self handleAuthRequest:aReason
							withOptions:nil
							 completion:^(BOOL didFinish, NSError *error)
	 {
	 WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	 
	 if (didFinish)
		 if (successBlock)
			 successBlock(ri.userIdentifier, ri.userToken, ri.primaryGroupIdentifier);
	 
	 }];
	
	return YES;

}

- (void) handleAuthRequest:(NSString *)reason withOptions:(NSDictionary *)options completion:(void(^)(BOOL didFinish, NSError *error))block {

	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	__weak WAAppDelegate_iOS *wAppDelegate = self;
	
	[ri.engine.queue cancelAllOperations];
	
	NSParameterAssert(!self.alreadyRequestingAuthentication);
	self.alreadyRequestingAuthentication = YES;

	void (^handleAuthSuccess)(void) = ^ {
	
		if (block)
			block(YES, nil);
			
		wAppDelegate.alreadyRequestingAuthentication = NO;
		[wAppDelegate subscribeRemoteNotification];
		
	};
	
	if (reason) {
		
		WAOverlayBezel *errorBezel = [[WAOverlayBezel alloc] initWithStyle:WAErrorBezelStyle];
		[errorBezel setCaption:reason];
		[errorBezel show];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
								[errorBezel dismiss];
							});
	
	}
	
	__block WAWelcomeViewController *welcomeVC = [WAWelcomeViewController controllerWithCompletion:^(NSString *token, NSDictionary *userRep, NSArray *groupReps, NSError *error) {
	
		if (error) {
		
			NSString *message = nil;
			if ([error code] == 0x9) {
				message = NSLocalizedString(@"AUTH_ERROR_INVALID_EMAIL_FORMAT", @"Authentication Error Description");
			} else if ([error code] == 0xb) {
				message = NSLocalizedString(@"AUTH_ERROR_INVALID_PWD_FORMAT", @"Authentication Error Description");
			} else if ([error code] == 0x1001) {
				message = NSLocalizedString(@"AUTH_ERROR_INVALID_EMAIL_PWD", @"Authentication Error Description");
			} else if ([error code] == 0x1002) {
				message = NSLocalizedString(@"AUTH_ERROR_ALREADY_REGISTERED", @"Authentication Error Description");
			} else {
				message = NSLocalizedString(@"AUTH_UNKNOWN_ERROR", @"Unknown Error");
			}
			IRAction *okAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_OKAY", @"Alert Dismissal Action") block:nil];
		
			IRAlertView *alertView = [IRAlertView alertViewWithTitle:nil message:message cancelAction:okAction otherActions:nil];
			[alertView show];
		
			welcomeVC = nil;
			return;
			
		}
		
		NSString *userID = [userRep valueForKeyPath:@"user_id"];
		
		NSString *primaryGroupID = [[[groupReps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		
			return [[evaluatedObject valueForKeyPath:@"creator_id"] isEqual:userID];
			
		}]] lastObject] valueForKeyPath:@"group_id"];
		
		WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
		
		ri.userIdentifier = userID;
		ri.userToken = token;
		ri.primaryGroupIdentifier = primaryGroupID;
		
		handleAuthSuccess();

		WAFirstUseViewController *firstUseVC = [WAFirstUseViewController initWithCompleteBlock:^{

			[wAppDelegate clearViewHierarchy];
			[wAppDelegate recreateViewHierarchy];
			
		}];

		switch ([UIDevice currentDevice].userInterfaceIdiom) {

			case UIUserInterfaceIdiomPad:
				firstUseVC.modalPresentationStyle = UIModalPresentationFormSheet;
				break;

			case UIUserInterfaceIdiomPhone:
				firstUseVC.modalPresentationStyle = UIModalPresentationCurrentContext;

		}
		
		[wAppDelegate clearViewHierarchy];
		[wAppDelegate.window.rootViewController presentViewController:firstUseVC animated:NO completion:nil];

	}];
	
	UINavigationController *authRequestWrapperVC = [[UINavigationController alloc] initWithRootViewController:welcomeVC];
	
	switch ([UIDevice currentDevice].userInterfaceIdiom) {
	
		case UIUserInterfaceIdiomPad: {
			authRequestWrapperVC.modalPresentationStyle = UIModalPresentationFormSheet;
			break;
		}
		
		case UIUserInterfaceIdiomPhone:
		default: {
			authRequestWrapperVC.modalPresentationStyle = UIModalPresentationCurrentContext;
		}

	}
	
	authRequestWrapperVC.navigationBar.tintColor =  [UIColor colorWithRed:98.0/255.0 green:176.0/255.0 blue:195.0/255.0 alpha:0.0];
	
	[self.window.rootViewController presentViewController:authRequestWrapperVC animated:NO completion:nil];
	
}

- (BOOL) isRunningAuthRequest {

	return self.alreadyRequestingAuthentication;

}

static NSInteger networkActivityStackingCount = 0;

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

	networkActivityStackingCount--;
	
	if (networkActivityStackingCount <= 0) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		networkActivityStackingCount = 0;
	}

}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

	if ([[url scheme] hasPrefix:@"fb"]) {
		[FBSession.activeSession handleOpenURL:url];
	} else {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			url, @"url",
			sourceApplication, @"sourceApplication",
			annotation, @"annotation",
		nil];

		[[NSNotificationCenter defaultCenter] postNotificationName:kWAApplicationDidReceiveRemoteURLNotification object:url userInfo:userInfo];
	}
	
  return YES;

}

#pragma mark UIApplication delegates

- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {

	WAPostAppEvent(@"did-receive-memory-warning", [NSDictionary dictionaryWithObjectsAndKeys:
	
		//	TBD
	
	nil]);

}

- (void)applicationWillTerminate:(UIApplication *)application {
	[FBSession.activeSession close];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[FBSession.activeSession handleDidBecomeActive];

	if ([self hasAuthenticationData]) {

		if (!self.photoImportManager) {
			self.photoImportManager = [[WAPhotoImportManager alloc] init];
		}
		if (self.photoImportManager.enabled) {
			[self.photoImportManager createPhotoImportArticlesWithCompletionBlock:^{
				NSLog(@"All photo import operations are enqueued");
			}];
		}

		if (!self.cacheManager) {
			self.cacheManager = [[WACacheManager alloc] init];
			self.cacheManager.delegate = self;
		}
		[self.cacheManager clearPurgeableFilesIfNeeded];

	}

}

#pragma mark WACacheManager delegates

- (BOOL)shouldPurgeCachedFile:(WACache *)cache {

	return YES;

}

@end


@implementation UINavigationController (KeyboardDismiss)

// implement this method to avoid non-auto-dismissed keyboard bug on iPad
// ref: http://stackoverflow.com/questions/3372333/ipad-keyboard-will-not-dismiss-if-modal-view-controller-presentation-style-is-ui
- (BOOL)disablesAutomaticKeyboardDismissal
{
	return NO;
}

@end
