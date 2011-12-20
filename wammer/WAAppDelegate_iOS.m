//
//  WAAppDelegate_iOS.m
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAAppDelegate_iOS.h"

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

#import "UIApplication+CrashReporting.h"
#import "WASetupViewController.h"

#import "WANavigationBar.h"

#import "UIView+IRAdditions.h"

#import "IRAlertView.h"
#import "IRAction.h"

#import "WAPostsViewControllerPhone.h"

#import "WAStationDiscoveryFeedbackViewController.h"

#import "IRLifetimeHelper.h"
#import "WAOverlayBezel.h"

#import "UIWindow+IRAdditions.h"

#import "IASKSettingsReader.h"


@interface WAAppDelegate_iOS () <WAApplicationRootViewControllerDelegate, WASetupViewControllerDelegate>

- (void) presentSetupViewControllerAnimated:(BOOL)animated;

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification;
- (void) handleObservedRemoteURLNotification:(NSNotification *)aNotification;
- (void) handleIASKSettingsChanged:(NSNotification *)aNotification;
- (void) handleIASKSettingsDidRequestAction:(NSNotification *)aNotification;

- (void) performUserOnboardingUsingAuthRequestViewController:(WAAuthenticationRequestViewController *)self;

@property (nonatomic, readwrite, assign) BOOL alreadyRequestingAuthentication;

- (void) clearViewHierarchy;
- (void) recreateViewHierarchy;

@end


@implementation WAAppDelegate_iOS
@synthesize window = _window;
@synthesize alreadyRequestingAuthentication;

- (id) init {

  self = [super init];
  if (!self)
    return nil;

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleObservedAuthenticationFailure:) name:kWARemoteInterfaceDidObserveAuthenticationFailureNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleObservedRemoteURLNotification:) name:kWAApplicationDidReceiveRemoteURLNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIASKSettingsChanged:) name:kIASKAppSettingChanged object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIASKSettingsDidRequestAction:) name:kWASettingsDidRequestActionNotification object:nil];
	
  return self;

}

- (void) dealloc {

  //  This is so not going to happen
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super dealloc];

}

- (void) bootstrap {
	
	[super bootstrap];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[WARemoteInterface sharedInterface].apiKey = kWARemoteEndpointApplicationKeyPad;
	else {
		[WARemoteInterface sharedInterface].apiKey = kWARemoteEndpointApplicationKeyPhone;
	}

	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		(id)kCFBooleanTrue, [[UIApplication sharedApplication] crashReportingEnabledUserDefaultsKey],
	nil]];

}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	[self bootstrap];

	[[UIApplication sharedApplication] setCrashReportRecipients:[[NSUserDefaults standardUserDefaults] arrayForKey:kWACrashReportRecipients]];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
	
	
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	self.window.backgroundColor = [UIColor blackColor];
	[self.window makeKeyAndVisible];
	
			
	void (^initializeInterface)() = ^ {
		
		if (![self hasAuthenticationData]) {
		
			[self applicationRootViewControllerDidRequestReauthentication:nil];
						
		} else {
		
			NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserIdentifier];
			
			if (lastAuthenticatedUserIdentifier)
				[WADataStore defaultStore].persistentStoreName = [lastAuthenticatedUserIdentifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			[self recreateViewHierarchy];
			
		}
    
	};
	
	
	//	UIApplication+CrashReporter shall only be used on a real device for now
	
	BOOL reportsCrashOnSimulator = NO;
	
	if (!reportsCrashOnSimulator && ([[UIDevice currentDevice].model rangeOfString:@"Simulator"].location != NSNotFound)) {
	
    //  Never send crash reports thru the Simulator since it won’t actually matter

		initializeInterface();
	
	} else {
  
    if (WAAdvancedFeaturesEnabled()) {
		
			[self clearViewHierarchy];
    
      //  Only enable crash reporting as an advanced feature
	
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
    
    } else {
      initializeInterface();
    }
	
	}
	
  return YES;
	
}

- (void) clearViewHierarchy {

	__block void (^dismissModal)(UIViewController *aVC);
	dismissModal = ^ (UIViewController *aVC) {
		
		if (aVC.modalViewController)
			dismissModal(aVC.modalViewController);
		else
			[aVC dismissModalViewControllerAnimated:NO];
	
	};
	
	dismissModal(self.window.rootViewController);
	
	
	WAViewController *bottomMostViewController = [[[WAViewController alloc] init] autorelease];
	bottomMostViewController.onShouldAutorotateToInterfaceOrientation = ^ (UIInterfaceOrientation toOrientation) {
		return YES;
	};
	bottomMostViewController.onLoadview = ^ (WAViewController *self) {
		self.view = [[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 1024, 1024 }] autorelease];
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternBlackPaper"]];
	};
	
	self.window.rootViewController = bottomMostViewController;

}

- (void) recreateViewHierarchy {

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
	
	__block UIViewController *presentedViewController = [[(UIViewController *)[NSClassFromString(rootViewControllerClassName) alloc] init] autorelease];
	
	self.window.rootViewController = (( ^ {
	
		__block WANavigationController *navController = [[WANavigationController alloc] initWithRootViewController:presentedViewController];
		
		navController.onViewDidLoad = ^ (WANavigationController *self) {
			self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternThickShrunkPaper"]];
			((WANavigationBar *)self.navigationBar).tintColor = [UIColor brownColor];
			((WANavigationBar *)self.navigationBar).backgroundView = [WANavigationBar defaultPatternBackgroundView];
		};
		
		if ([navController isViewLoaded])
			navController.onViewDidLoad(navController);
		
		return navController;
		
	})());
	
	if ([presentedViewController conformsToProtocol:@protocol(WAApplicationRootViewController)])
		[(id<WAApplicationRootViewController>)presentedViewController setDelegate:self];
			
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];

}





- (void) applicationRootViewControllerDidRequestReauthentication:(id<WAApplicationRootViewController>)controller {

	dispatch_async(dispatch_get_main_queue(), ^ {

		//	[self presentAuthenticationRequestRemovingPriorData:YES clearingNavigationHierarchy:YES runningOnboardingProcess:YES];
		
		void (^writeCredentials)(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) = ^ (NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
		
			[self updateCurrentCredentialsWithUserIdentifier:userIdentifier token:userToken primaryGroup:primaryGroupIdentifier];
		
		};

		[self presentAuthenticationRequestWithReason:nil allowingCancellation:NO removingPriorData:YES clearingNavigationHierarchy:YES onAuthSuccess:^(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
		
			writeCredentials(userIdentifier, userToken, primaryGroupIdentifier);
			[WADataStore defaultStore].persistentStoreName = userIdentifier;
			//	HECKLING ?
			
		} runningOnboardingProcess:YES];
			
	});

}

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification {

  dispatch_async(dispatch_get_main_queue(), ^{

		[self presentAuthenticationRequestWithReason:@"Token Expired" allowingCancellation:YES removingPriorData:NO clearingNavigationHierarchy:NO runningOnboardingProcess:NO];

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
	
	void (^confirmURLChange)(NSString *defaultsKey, NSString *newString, NSString *alertTitleKey, NSString *alertTextKey) = ^ (NSString *defaultsKey, NSString *newString, NSString *alertTitleKey, NSString *alertTextKey) {
	
		if (!newString)
			return;
		
		NSURL *oldURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:defaultsKey]];
		NSURL *newURL = [NSURL URLWithString:newString];
		
		[[NSUserDefaults standardUserDefaults] setObject:newString forKey:defaultsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		__block __typeof__(self) nrSelf = self;
		
		void (^zapAndRequestReauthentication)() = ^ {

			if (self.alreadyRequestingAuthentication) {
				nrSelf.alreadyRequestingAuthentication = NO;
				[nrSelf clearViewHierarchy];
			}
			
			[nrSelf applicationRootViewControllerDidRequestReauthentication:nil];
			
		};
		
		NSString *alertTitle = NSLocalizedString(alertTitleKey, nil);
		NSString *alertText = [NSString stringWithFormat:
			NSLocalizedString(alertTextKey, nil),
			[oldURL absoluteString],
			[newURL absoluteString]
		];
		
		IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionCancel", nil) block:nil];
		IRAction *signOutAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionReset", nil) block:zapAndRequestReauthentication];
		
		[[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:
			signOutAction,
		nil]] show];
	
	};
	
	if ([command isEqualToString:kWACallbackActionSetRemoteEndpointURL]) {
	
		confirmURLChange(
			kWARemoteEndpointURL,
			[params objectForKey:@"url"],
			@"WARemoteEndpointURLChangeConfirmationTitle",
			@"WARemoteEndpointURLChangeConfirmationDescription"
		);
	
	} else if ([command isEqualToString:kWACallbackActionSetUserRegistrationEndpointURL]) {
	
		confirmURLChange(
			kWAUserRegistrationEndpointURL,
			[params objectForKey:@"url"],
			@"WAUserRegistrationEndpointURLChangeConfirmationTitle",
			@"WAUserRegistrationEndpointURLChangeConfirmationDescription"
		);
	
	} else if ([command isEqualToString:kWACallbackActionSetUserPasswordResetEndpointURL]) {

		confirmURLChange(
			kWAUserPasswordResetEndpointURL,
			[params objectForKey:@"url"],
			@"WAUserPasswordResetEndpointURLChangeConfirmationTitle",
			@"WAUserPasswordResetEndpointURLChangeConfirmationDescription"
		);
	
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
		
		NSString *alertTitle = NSLocalizedString(@"WAResetSettingsConfirmationTitle", nil);
		NSString *alertText = NSLocalizedString(@"WAResetSettingsConfirmationDescription", nil);
	
		IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionCancel", nil) block:nil];
		IRAction *resetAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionReset", nil) block: ^ {
		
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
		alertTitle = NSLocalizedString(@"WAAdvancedFeaturesEnabledTitle", nil);
		alertText = NSLocalizedString(@"WAAdvancedFeaturesEnabledDescription", nil);
	} else {
		alertTitle = NSLocalizedString(@"WAAdvancedFeaturesDisabledTitle", nil);
		alertText = NSLocalizedString(@"WAAdvancedFeaturesDisabledDescription", nil);
	}

	IRAction *okayAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionOkay", nil) block:nil];
	IRAction *okayAndZapAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionOkay", nil) block:zapAndRequestReauthentication];
	IRAction *laterAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionLater", nil) block:nil];
	IRAction *signOutAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionSignOut", nil) block:zapAndRequestReauthentication];
	
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
	
  NSString *capturedCurrentUserIdentifier = [WARemoteInterface sharedInterface].userIdentifier;
  BOOL (^userIdentifierChanged)() = ^ {
    return (BOOL)![[WARemoteInterface sharedInterface].userIdentifier isEqualToString:capturedCurrentUserIdentifier];
  };
  
  if (allowsCancellation)
    NSParameterAssert(!eraseAuthInfo);

	if (eraseAuthInfo)
    [self removeAuthenticationData];
	
	if (zapEverything)
		[self clearViewHierarchy];

	
  __block WAAuthenticationRequestViewController *authRequestVC;
	
	void (^presentWrappedAuthRequestVC)(WAAuthenticationRequestViewController *authVC, BOOL animated) = ^ (WAAuthenticationRequestViewController *authVC, BOOL animated) {
	
		WANavigationController *authRequestWrappingVC = [[[WANavigationController alloc] initWithRootViewController:authVC] autorelease];
		authRequestWrappingVC.modalPresentationStyle = UIModalPresentationFormSheet;
		authRequestWrappingVC.disablesAutomaticKeyboardDismissal = NO;
	
		[self.window.rootViewController presentModalViewController:authRequestWrappingVC animated:animated];
		return;
	
		switch (UI_USER_INTERFACE_IDIOM()) {
		
			//  FIXME: Move this in a CustomUI category
		
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
				
				if (self.window.rootViewController.modalViewController)
					[self.window.rootViewController.modalViewController dismissModalViewControllerAnimated:NO];
				
				[self.window.rootViewController presentModalViewController:fullscreenBaseVC animated:NO];
				[fullscreenBaseVC presentModalViewController:authRequestWrappingVC animated:animated];
				
				break;
			
			}
			
			case UIUserInterfaceIdiomPhone:
			default: {
			
				if (self.window.rootViewController.modalViewController)
					[self.window.rootViewController.modalViewController dismissModalViewControllerAnimated:NO];
				
				[self.window.rootViewController presentModalViewController:authRequestWrappingVC animated:animated];
				break;
				
			}
		
		}
	
	};
  
  IRAction *resetPasswordAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionResetPassword", @"Action title for resetting password") block: ^ {
  
    authRequestVC.password = nil;
    [authRequestVC assignFirstResponderStatusToBestMatchingField];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWAUserPasswordResetEndpointURL]]];
  
  }];

  IRAction *registerUserAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionRegisterUser", @"Action title for registering") block: ^ {
  
    __block WARegisterRequestViewController *registerRequestVC = [WARegisterRequestViewController controllerWithCompletion:^(WARegisterRequestViewController *self, NSError *error) {
    
      if (error) {
        
        NSString *alertTitle = NSLocalizedString(@"WAErrorUserRegistrationFailedTitle", @"Title for registration failure");
        
        NSString *alertText = [[NSArray arrayWithObjects:
          NSLocalizedString(@"WAErrorUserRegistrationFailedDescription", @"Description for registration failure"),
          [NSString stringWithFormat:@"“%@”.", [error localizedDescription]], @"\n\n",
          NSLocalizedString(@"WAErrorUserRegistrationFailedRecoveryNotion", @"Recovery notion for registration failure recovery"),
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
  
  IRAction *signInUserAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionSignIn", @"Action title for signing in") block:^{
    
    [authRequestVC authenticate];
    
  }];
  
  
  __block __typeof__(self) nrAppDelegate = self;
  
  authRequestVC = [WAAuthenticationRequestViewController controllerWithCompletion: ^ (WAAuthenticationRequestViewController *self, NSError *anError) {
  
      if (anError) {
      
        NSString *alertTitle = NSLocalizedString(@"WAErrorAuthenticationFailedTitle", @"Title for authentication failure");
        NSString *alertText = [[NSArray arrayWithObjects:
          NSLocalizedString(@"WAErrorAuthenticationFailedDescription", @"Description for authentication failure"),
          [NSString stringWithFormat:@"“%@”.", [anError localizedDescription]], @"\n\n",
          NSLocalizedString(@"WAErrorAuthenticationFailedRecoveryNotion", @"Recovery notion for authentication failure recovery"),
        nil] componentsJoinedByString:@""];
        
        [[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:[IRAction actionWithTitle:NSLocalizedString(@"WAActionCancel", @"Action title for cancelling") block:^{
        
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
			
			if (zapEverything) {
				UINavigationController *navC = [self.navigationController retain];
				[self dismissModalViewControllerAnimated:NO];
				[nrAppDelegate recreateViewHierarchy];
				[nrAppDelegate.window.rootViewController presentModalViewController:navC animated:NO];
			}
  
      if (userIdentifierChanged() || shouldRunOnboardingChecksIfUserUnchanged) {
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
	
		UIView *returnedView = [[[UIView alloc] initWithFrame:rootView.bounds] autorelease];
		returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		
		UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
		
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
                
                  WAStationDiscoveryFeedbackViewController *stationDiscoveryFeedbackVC = [[[WAStationDiscoveryFeedbackViewController alloc] init] autorelease];
                  UINavigationController *stationDiscoveryNavC = [stationDiscoveryFeedbackVC wrappingNavigationController];
                  stationDiscoveryFeedbackVC.dismissalAction = [IRAction actionWithTitle:NSLocalizedString(@"WAActionSignOut", @"Action title for signing the user out") block:^{
                    
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
      
        [IRAction actionWithTitle:NSLocalizedString(@"WAActionOkay", @"Action title for accepting what happened reluctantly") block:nil],
      
      nil]];
    
			[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
    });
    
  }];

}

- (void) applicationRootViewControllerDidRequestChangeAPIURL:(id<WAApplicationRootViewController>)controller {
	
	[self presentSetupViewControllerAnimated:YES];
	
}

- (void) presentSetupViewControllerAnimated:(BOOL)animated {
	
	WASetupViewController *setupVC = [[[WASetupViewController alloc] initWithAPIURLString:[[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointURL]] autorelease];
	setupVC.delegate = self;
	[setupVC presentModallyOn:self.window.rootViewController animated:animated];
	
}

- (void) setupViewController:(WASetupViewController *)controller didChooseString:(NSString *)string {

	NSParameterAssert(controller);
	NSParameterAssert(string);
  
  [[NSUserDefaults standardUserDefaults] setObject:string forKey:kWARemoteEndpointURL];
	[[NSUserDefaults standardUserDefaults] synchronize];

  //	TODO
	//	Update remote interface context here. Right now the API update only works when the app is killed and restarted.	
	
	//	This will work:
	//	[[WARemoteInterface sharedInterface].engine performSelector:@selector(setContext:) withObject:[WARemoteInterfaceContext context]];
	
  [controller dismissModalViewControllerAnimated:YES];

}

- (void) setupViewControllerDidCancel:(WASetupViewController *)controller{
	
	[controller dismissModalViewControllerAnimated:YES];
	
}

#pragma mark - Network Activity

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

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

  [[NSNotificationCenter defaultCenter] postNotificationName:kWAApplicationDidReceiveRemoteURLNotification object:url userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
  
    url, @"url",
    sourceApplication, @"sourceApplication",
    annotation, @"annotation",
  
  nil]];

  return YES;

}

@end
