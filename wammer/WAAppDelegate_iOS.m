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

#import "WAViewController.h"
#import "WANavigationController.h"

#import "WAAuthenticationRequestViewController.h"
#import "WARegisterRequestViewController.h"

#import "WARemoteInterface.h"

#import "WAApplicationRootViewControllerDelegate.h"

#import "WANavigationBar.h"

#import "UIView+IRAdditions.h"

#import "IRAlertView.h"
#import "IRAction.h"

#import "WATimelineViewControllerPhone.h"

#import "WAStationDiscoveryFeedbackViewController.h"

#import "IRLifetimeHelper.h"
#import "WAOverlayBezel.h"

#import "UIWindow+IRAdditions.h"

#import "IASKSettingsReader.h"

#import	"DCIntrospect.h"

#import "GANTracker.h"
		
@interface WAAppDelegate_iOS () <WAApplicationRootViewControllerDelegate>

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification;
- (void) handleObservedRemoteURLNotification:(NSNotification *)aNotification;
- (void) handleIASKSettingsChanged:(NSNotification *)aNotification;
- (void) handleIASKSettingsDidRequestAction:(NSNotification *)aNotification;

- (void) performUserOnboardingUsingAuthRequestViewController:(WAAuthenticationRequestViewController *)self;

@property (nonatomic, readwrite, assign) BOOL alreadyRequestingAuthentication;

- (void) clearViewHierarchy;
- (void) recreateViewHierarchy;
- (void) handleDebugModeToggled;

@end


@implementation WAAppDelegate_iOS
@synthesize window = _window;
@synthesize alreadyRequestingAuthentication;

- (void) dealloc {

  //  This is so not going to happen
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[GANTracker sharedTracker] stopTracker];

}

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
		
			NSLog(@"Using Testflight");
					
			[TestFlight setOptions:[NSDictionary dictionaryWithObjectsAndKeys:
				//	(id)kCFBooleanFalse, @"reinstallCrashHandlers",
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
			
			NSLog(@"Using Crashlytics");
			
			[Crashlytics startWithAPIKey:@"d79b0f823e42fdf1cdeb7e988a8453032fd85169"];
			[Crashlytics sharedInstance].debugMode = YES;
			
		});
	
		WF_GOOGLEANALYTICS(^ {
		
			NSLog(@"Using Google Analytics");
					
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
	
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	[self bootstrap];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	[[UIApplication sharedApplication] setStatusBarHidden:NO];
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor blackColor];
	[self.window makeKeyAndVisible];
	
	if ([[NSUserDefaults standardUserDefaults] stringForKey:kWADebugPersistentStoreName]) {
		
		[WADataStore defaultStore].persistentStoreName = [[NSUserDefaults standardUserDefaults] stringForKey:kWADebugPersistentStoreName];
		
		[self recreateViewHierarchy];
	
	} else if (![self hasAuthenticationData]) {
	
		[self applicationRootViewControllerDidRequestReauthentication:nil];
					
	} else {
	
		NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserIdentifier];
		
		if (lastAuthenticatedUserIdentifier)
			[WADataStore defaultStore].persistentStoreName = [lastAuthenticatedUserIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		[self recreateViewHierarchy];
		
	}

	#if TARGET_IPHONE_SIMULATOR
	// create a custom tap gesture recognizer so introspection can be invoked from a device
	// this one is a three finger double tap
	UITapGestureRecognizer *defaultGestureRecognizer = [[UITapGestureRecognizer alloc] init];
	defaultGestureRecognizer.cancelsTouchesInView = NO;
	defaultGestureRecognizer.delaysTouchesBegan = NO;
	defaultGestureRecognizer.delaysTouchesEnded = NO;
	defaultGestureRecognizer.numberOfTapsRequired = 3;
	defaultGestureRecognizer.numberOfTouchesRequired = 2;
	[DCIntrospect sharedIntrospector].invokeGestureRecognizer = defaultGestureRecognizer;

	// always insert this AFTER makeKeyAndVisible so statusBarOrientation is reported correctly.
	[[DCIntrospect sharedIntrospector] start];
	#endif
	
	WAPostAppEvent(@"AppVisit", [NSDictionary dictionaryWithObjectsAndKeys:@"app",@"category",@"visit", @"action", nil]);

  return YES;
	
}

- (void) clearViewHierarchy {

	__block void (^dismissModal)(UIViewController *) = ^ (UIViewController *aVC) {
		
		if (aVC.modalViewController)
			dismissModal(aVC.modalViewController);
		else
			[aVC dismissModalViewControllerAnimated:NO];
	
	};
	
	UIViewController *rootVC = self.window.rootViewController;
	
	dismissModal(rootVC);

	WAViewController *bottomMostViewController = [[WAViewController alloc] init];
	bottomMostViewController.onShouldAutorotateToInterfaceOrientation = ^ (UIInterfaceOrientation toOrientation) {
		return YES;
	};
	bottomMostViewController.onLoadview = ^ (WAViewController *self) {
		self.view = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 1024, 1024 }];
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternBlackPaper"]];
	};
	
	self.window.rootViewController = bottomMostViewController;
	[rootVC didReceiveMemoryWarning];	//	Kill it now
	
}

- (void) recreateViewHierarchy {

	NSOperationQueue *queue = [IRRemoteResourcesManager sharedManager].queue;
	[queue cancelAllOperations];
	
	

	NSString *rootViewControllerClassName = nil;
		
	switch (UI_USER_INTERFACE_IDIOM()) {
		case UIUserInterfaceIdiomPad: {
			rootViewControllerClassName = @"WADiscretePaginatedArticlesViewController";
			break;
		}
		default:
		case UIUserInterfaceIdiomPhone: {
			rootViewControllerClassName = @"WATimelineViewControllerPhone";
			break;
		}
	}
	
	NSParameterAssert(rootViewControllerClassName);
	
	__block UIViewController *presentedViewController = [(UIViewController *)[NSClassFromString(rootViewControllerClassName) alloc] init];
	
	self.window.rootViewController = (( ^ {
	
		__block WANavigationController *navController = [[WANavigationController alloc] initWithRootViewController:presentedViewController];
		
		navController.onViewDidLoad = ^ (WANavigationController *self) {
			
			self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternThickShrunkPaper"]];
			
			__block WANavigationBar *navigationBar = (WANavigationBar *)self.navigationBar;
			
			navigationBar.tintColor = [UIColor brownColor];
			navigationBar.customBackgroundView = [WANavigationBar defaultPatternBackgroundView];
			
			navigationBar.onBarStyleContextChanged = ^ {
			
				[UIView animateWithDuration:0.3 animations:^{
					
					BOOL isTranslucent = (navigationBar.barStyle == UIBarStyleBlackTranslucent) || ((navigationBar.barStyle == UIBarStyleBlack) && navigationBar.translucent);
					
					navigationBar.customBackgroundView.alpha = isTranslucent ? 0 : 1;
					navigationBar.suppressesDefaultAppearance = isTranslucent ? NO : YES;
					
					navigationBar.tintColor = isTranslucent ? nil : [UIColor brownColor];
			
				}];
			
			};
			
		};
		
		if ([navController isViewLoaded])
			navController.onViewDidLoad(navController);
		
		return navController;
		
	})());
	
	if ([presentedViewController conformsToProtocol:@protocol(WAApplicationRootViewController)])
		[(id<WAApplicationRootViewController>)presentedViewController setDelegate:self];
			
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];

}





- (void) applicationRootViewControllerDidRequestReauthentication:(id<WAApplicationRootViewController>)controller {

	dispatch_async(dispatch_get_main_queue(), ^ {

		[self presentAuthenticationRequestWithReason:nil allowingCancellation:NO removingPriorData:YES clearingNavigationHierarchy:YES onAuthSuccess:^(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
		
			[self updateCurrentCredentialsWithUserIdentifier:userIdentifier token:userToken primaryGroup:primaryGroupIdentifier];
			[WADataStore defaultStore].persistentStoreName = userIdentifier;
			
		} runningOnboardingProcess:YES];
		
		NSParameterAssert(self.alreadyRequestingAuthentication);
			
	});

}

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification {

	NSError *error = [[aNotification userInfo] objectForKey:@"error"];

  dispatch_async(dispatch_get_main_queue(), ^{

		[self presentAuthenticationRequestWithReason:[error localizedDescription] allowingCancellation:YES removingPriorData:NO clearingNavigationHierarchy:NO onAuthSuccess:^(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
			
			[self updateCurrentCredentialsWithUserIdentifier:userIdentifier token:userToken primaryGroup:primaryGroupIdentifier];
			[WADataStore defaultStore].persistentStoreName = userIdentifier;
			
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
	
		__block __typeof__(self) nrSelf = self;
		
		NSString *alertTitle = NSLocalizedString(@"RESET_SETTINGS_CONFIRMATION_TITLE", nil);
		NSString *alertText = NSLocalizedString(@"RESET_SETTINGS_CONFIRMATION_DESCRIPTION", nil);
	
		IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
		IRAction *resetAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_RESET", nil) block: ^ {
		
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
			for (NSString *key in [[defaults dictionaryRepresentation] allKeys])
				[defaults removeObjectForKey:key];
				
			[defaults synchronize];
			
			[nrSelf clearViewHierarchy];
			[nrSelf recreateViewHierarchy];
		
		}];
		
		IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:
			
			resetAction,
			
		nil]];
		
		[alertView show];
	
	}

}

- (void) handleDebugModeToggled {

	__block __typeof__(self) nrSelf = self;
	
	BOOL isNowEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kWAAdvancedFeaturesEnabled];
	
	NSString *alertTitle;
	NSString *alertText;
	IRAlertView *alertView = nil;
	
	void (^zapAndRequestReauthentication)() = ^ {
	
		if (self.alreadyRequestingAuthentication) {
			nrSelf.alreadyRequestingAuthentication = NO;
			[nrSelf clearViewHierarchy];
		}
		
		[nrSelf applicationRootViewControllerDidRequestReauthentication:nil];
		
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

- (BOOL) presentAuthenticationRequestRemovingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged {

  return [self presentAuthenticationRequestWithReason:nil allowingCancellation:NO removingPriorData:eraseAuthInfo clearingNavigationHierarchy:zapEverything runningOnboardingProcess:shouldRunOnboardingChecksIfUserUnchanged];

}

- (BOOL) presentAuthenticationRequestWithReason:(NSString *)aReason allowingCancellation:(BOOL)allowsCancellation removingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged {

	return [self presentAuthenticationRequestWithReason:aReason allowingCancellation:allowsCancellation removingPriorData:eraseAuthInfo clearingNavigationHierarchy:zapEverything onAuthSuccess:nil runningOnboardingProcess:shouldRunOnboardingChecksIfUserUnchanged];

}

- (BOOL) presentAuthenticationRequestWithReason:(NSString *)aReason allowingCancellation:(BOOL)allowsCancellation removingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything onAuthSuccess:(void (^)(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier))successBlock runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged {

  @synchronized (self) {
    
    if (self.alreadyRequestingAuthentication)
      return NO;
    
    self.alreadyRequestingAuthentication = YES;
  
  }
	
  if (allowsCancellation)
    NSParameterAssert(!eraseAuthInfo);

	if (eraseAuthInfo)
    [self removeAuthenticationData];
	
	if (zapEverything)
		[self clearViewHierarchy];
	
	
  NSString *capturedCurrentUserIdentifier = [WARemoteInterface sharedInterface].userIdentifier;
  BOOL (^userIdentifierChanged)() = ^ {
	
		NSString *currentID = [WARemoteInterface sharedInterface].userIdentifier;
	
		NSLog(@"Old ID: %@", capturedCurrentUserIdentifier);
		NSLog(@"New ID: %@", currentID);
		
    return (BOOL)![currentID isEqualToString:capturedCurrentUserIdentifier];
		
  };  
	
	
  __block WAAuthenticationRequestViewController *authRequestVC;
	
	void (^presentWrappedAuthRequestVC)(WAAuthenticationRequestViewController *authVC, BOOL animated) = ^ (WAAuthenticationRequestViewController *authVC, BOOL animated) {
	
		WANavigationController *authRequestWrappingVC = [[WANavigationController alloc] initWithRootViewController:authVC];
		authRequestWrappingVC.modalPresentationStyle = UIModalPresentationFormSheet;
		authRequestWrappingVC.disablesAutomaticKeyboardDismissal = NO;
	
		[self.window.rootViewController presentModalViewController:authRequestWrappingVC animated:animated];
			
	};
  
  IRAction *resetPasswordAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_RESET_PASSWORD", @"Action title for resetting password") block: ^ {
  
    authRequestVC.password = nil;
    [authRequestVC assignFirstResponderStatusToBestMatchingField];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWAUserPasswordResetEndpointURL]]];
  
  }];

  IRAction *registerUserAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_REGISTER_USER", @"Action title for registering") block: ^ {
  
    __block WARegisterRequestViewController *registerRequestVC = [WARegisterRequestViewController controllerWithCompletion:^(WARegisterRequestViewController *self, NSError *error) {
    
      if (error) {
        
        NSString *alertTitle = NSLocalizedString(@"ERROR_USER_REGISTRATION_FAILED_TITLE", @"Title for registration failure");
        
        NSString *alertText = [[NSArray arrayWithObjects:
          NSLocalizedString(@"ERROR_USER_REGISTRATION_FAILED_DESCRIPTION", @"Description for registration failure"),
          [NSString stringWithFormat:@"“%@”.", [error localizedDescription]], @"\n\n",
          NSLocalizedString(@"ERROR_USER_REGISTRATION_FAILED_RECOVERY_NOTION", @"Recovery notion for registration failure recovery"),
        nil] componentsJoinedByString:@""];

        [[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:nil otherActions:[NSArray arrayWithObjects:
        
          [IRAction actionWithTitle:@"OK" block:nil],
        
        nil]] show];
        
        return;
      
      }
      
      authRequestVC.username = self.username;
      authRequestVC.password = self.password;
      authRequestVC.performsAuthenticationOnViewDidAppear = YES;

      [authRequestVC.tableView reloadData];
      [authRequestVC.navigationController popToViewController:authRequestVC animated:YES];

    }];
  
    registerRequestVC.username = authRequestVC.username;
    registerRequestVC.password = authRequestVC.password;
    
    [authRequestVC.navigationController pushViewController:registerRequestVC animated:YES];
  
  }];
  
  IRAction *signInUserAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_IN", @"Action title for signing in") block:^{
    
    [authRequestVC authenticate];
    
  }];
  
  
  __block __typeof__(self) nrAppDelegate = self;
  
  authRequestVC = [WAAuthenticationRequestViewController controllerWithCompletion: ^ (WAAuthenticationRequestViewController *self, NSError *anError) {
  
      if (anError) {
      
        NSString *alertTitle = NSLocalizedString(@"ERROR_AUTHENTICATION_FAILED_TITLE", @"Title for authentication failure");
        NSString *alertText = [[NSArray arrayWithObjects:
          NSLocalizedString(@"ERROR_AUTHENTICATION_FAILED_DESCRIPTION", @"Description for authentication failure"),
          [NSString stringWithFormat:@"“%@”.", [anError localizedDescription]], @"\n\n",
          NSLocalizedString(@"ERROR_AUTHENTICATION_FAILED_RECOVERY_NOTION", @"Recovery notion for authentication failure recovery"),
        nil] componentsJoinedByString:@""];
        
        [[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:[IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Action title for cancelling") block:^{
        
          authRequestVC.password = nil;
          [authRequestVC assignFirstResponderStatusToBestMatchingField];
          
        }] otherActions:[NSArray arrayWithObjects:
          
          resetPasswordAction,
          registerUserAction,
          
        nil]] show];
        
        return;
      
      }
			
			WARemoteInterface *ri = [WARemoteInterface sharedInterface];
			
			if (successBlock)
				successBlock(ri.userIdentifier, ri.userToken, ri.primaryGroupIdentifier);
				
			BOOL userIdentifierHasChanged = userIdentifierChanged();
			
			if (userIdentifierHasChanged || zapEverything) {
				UINavigationController *navC = self.navigationController;
				[self dismissModalViewControllerAnimated:NO];
				[nrAppDelegate recreateViewHierarchy];
				[nrAppDelegate.window.rootViewController presentModalViewController:navC animated:NO];
			}
  
			if (userIdentifierHasChanged || shouldRunOnboardingChecksIfUserUnchanged) {
        [nrAppDelegate performUserOnboardingUsingAuthRequestViewController:self];
      } else {
        [self dismissModalViewControllerAnimated:YES];
      }
            
			nrAppDelegate.alreadyRequestingAuthentication = NO;

  }];
  
  if (aReason)
    authRequestVC.navigationItem.prompt = aReason;
  
  if (allowsCancellation) {
    authRequestVC.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemCancel wiredAction:^(IRBarButtonItem *senderItem) {
		
      [authRequestVC.navigationController dismissModalViewControllerAnimated:YES];
			
			nrAppDelegate.alreadyRequestingAuthentication = NO;
			
    }];
  }
  
  [signInUserAction irBind:@"enabled" toObject:authRequestVC keyPath:@"validForAuthentication" options:[NSDictionary dictionaryWithObjectsAndKeys:
    (id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
  nil]];
  [authRequestVC irPerformOnDeallocation:^{
    [signInUserAction irUnbind:@"enabled"];
  }];
  
  NSMutableArray *authRequestActions = [NSMutableArray arrayWithObjects:
    
    signInUserAction,
    registerUserAction,
    
  nil];

  if (WAAdvancedFeaturesEnabled()) {
		
		[authRequestActions addObject:[IRAction actionWithTitle:@"Debug Fill" block:^{

			authRequestVC.username = [[NSUserDefaults standardUserDefaults] stringForKey:kWADebugAutologinUserIdentifier];
			authRequestVC.password = [[NSUserDefaults standardUserDefaults] stringForKey:kWADebugAutologinUserPassword];
			[authRequestVC authenticate];

		}]];
		
	}

	authRequestVC.actions = authRequestActions;

	presentWrappedAuthRequestVC(authRequestVC, NO);

	return YES;

}

- (void) performUserOnboardingUsingAuthRequestViewController:(WAAuthenticationRequestViewController *)authVC {

	NSParameterAssert([NSThread isMainThread]);

	__block __typeof__(self) nrAppDelegate = self;

	UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
	UIViewController *rootVC = keyWindow.rootViewController;
	UIView *rootView = rootVC.view;
	
	UIView *overlayView = ((^ {
	
		UIView *returnedView = [[UIView alloc] initWithFrame:rootView.bounds];
		returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		
		UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		
		spinner.center = (CGPoint){
			CGRectGetMidX(returnedView.bounds),
			CGRectGetMidY(returnedView.bounds)
		};
		
		spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
		
		[spinner startAnimating];
		
		[returnedView addSubview:spinner];
		returnedView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
	
		return returnedView;
	
	})());
	
	void (^addOverlayView)(void) = ^ {
	
		[rootVC.view addSubview:overlayView];	
		overlayView.frame = rootVC.view.bounds;
	
	};
	
	void (^removeOverlayView)(BOOL) = ^ (BOOL animated) {
		
		[UIView animateWithDuration:(animated ? 0.3f : 0.0f) delay:0.0f options:0 animations:^{
		
			overlayView.alpha = 0.0f;
			
		} completion:^(BOOL finished) {
		
			[overlayView removeFromSuperview];
			
		}];
		
	};
	
	
	__block WAOverlayBezel *nrBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
	
	
	//	Always request reauth beyond this point
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAUserRequiresReauthentication];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	
	[[WADataStore defaultStore] updateCurrentUserOnSuccess: ^ {

    dispatch_async(dispatch_get_main_queue(), ^{
            
      void (^operations)() = ^ {
          
					addOverlayView();	
          [keyWindow.rootViewController dismissModalViewControllerAnimated:YES];
          
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
					
						[[WARemoteInterface sharedInterface] retrieveUser:[WARemoteInterface sharedInterface].userIdentifier onSuccess:^(NSDictionary *userRep, NSArray *groupReps) {
							
							BOOL userNeedsStation = [[userRep valueForKeyPath:@"state"] isEqual:@"station_required"];
							
              dispatch_async(dispatch_get_main_queue(), ^ {
              
                if (!userNeedsStation) {
                
                  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAUserRequiresReauthentication];
                  [[NSUserDefaults standardUserDefaults] synchronize];

                  removeOverlayView(YES);
									[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
                
                } else {
                
                  WAStationDiscoveryFeedbackViewController *stationDiscoveryFeedbackVC = [[WAStationDiscoveryFeedbackViewController alloc] init];
                  UINavigationController *stationDiscoveryNavC = [stationDiscoveryFeedbackVC wrappingNavigationController];
                  stationDiscoveryFeedbackVC.dismissalAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", @"Action title for signing the user out") block:^{
                    
                    removeOverlayView(NO);
                    [stationDiscoveryNavC dismissModalViewControllerAnimated:NO];
                    [nrAppDelegate applicationRootViewControllerDidRequestReauthentication:nil];
                    
                  }];
									
									void (^finalizeOnboarding)(void) = ^ {
									
										[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAUserRequiresReauthentication];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    [stationDiscoveryFeedbackVC dismissModalViewControllerAnimated:YES];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                      removeOverlayView(YES);
                    });
									
									};
									
									if (WAAdvancedFeaturesEnabled()) {
									
										//	Alright!
										
										stationDiscoveryFeedbackVC.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithTitle:@"I don’t care" action:^{
											finalizeOnboarding();
										}];
										
									}
                  
									[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
                  [rootVC presentModalViewController:stationDiscoveryNavC animated:YES];
                  
                  __block id notificationListener = [[NSNotificationCenter defaultCenter] addObserverForName:kWARemoteInterfaceReachableHostsDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
                  
                    WARemoteInterface *interface = [note object];
                    
                    if ([interface.monitoredHosts count] <= 1) {
                    
                      return;
                    
                      //  Damned shabby check
                      //  Should refactor
                    
                    }
                    
                   finalizeOnboarding();
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                    
                      [[NSNotificationCenter defaultCenter] removeObserver:notificationListener];
                      objc_setAssociatedObject(stationDiscoveryFeedbackVC, &kWARemoteInterfaceReachableHostsDidChangeNotification, nil, OBJC_ASSOCIATION_ASSIGN);
                      
                    });
                    
                  }];
                
                  objc_setAssociatedObject(stationDiscoveryFeedbackVC, &kWARemoteInterfaceReachableHostsDidChangeNotification, notificationListener, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                
                }
              
              });
              
            } onFailure:^(NSError *error) {
            
              dispatch_async(dispatch_get_main_queue(), ^ {
            
                NSLog(@"Error retrieving user information: %@", error);  //  FAIL
                removeOverlayView(YES);
								[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
              
              });
              
            }];
            
          });
          
      };
      
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0f * NSEC_PER_SEC), dispatch_get_main_queue(), operations);
    
    });
    
  } onFailure: ^ {
  
    dispatch_async(dispatch_get_main_queue(), ^{

      [IRAlertView alertViewWithTitle:@"Error Retrieving User Information" message:@"Unable to retrieve user metadata." cancelAction:nil otherActions:[NSArray arrayWithObjects:
      
        [IRAction actionWithTitle:NSLocalizedString(@"ACTION_OKAY", @"Action title for accepting what happened reluctantly") block:nil],
      
      nil]];
    
			[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
    });
    
  }];

}


#pragma mark - Network Activity

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
