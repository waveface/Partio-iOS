//
//  WAAppDelegate.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WADefines.h"

#import "WAAppDelegate.h"

#import "IRRemoteResourcesManager.h"
#import "IRRemoteResourceDownloadOperation.h"

#import "IRWebAPIEngine+ExternalTransforms.h"

#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WAViewController.h"
#import "WANavigationController.h"

#import "WAAuthenticationRequestViewController.h"
#import "WARegisterRequestViewController.h"

#import "WARemoteInterface.h"
#import "IRKeychainManager.h"

#import "WAApplicationRootViewControllerDelegate.h"

#import "UIApplication+CrashReporting.h"
#import "WASetupViewController.h"

#import "WANavigationBar.h"

#import "UIView+IRAdditions.h"

#import "IRAlertView.h"
#import "IRAction.h"

@interface WAAppDelegate () <IRRemoteResourcesManagerDelegate, WAApplicationRootViewControllerDelegate, WASetupViewControllerDelegate>

- (void) presentSetupViewControllerAnimated:(BOOL)animated;
- (void) configureRemoteResourceDownloadOperation:(IRRemoteResourceDownloadOperation *)anOperation;

@end


@implementation WAAppDelegate
@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	__block __typeof__(self) nrSelf = self;

	WARegisterUserDefaults();
	
	[IRRemoteResourcesManager sharedManager].delegate = self;
	[IRRemoteResourcesManager sharedManager].queue.maxConcurrentOperationCount = 4;
	[IRRemoteResourcesManager sharedManager].onRemoteResourceDownloadOperationWillBegin = ^ (IRRemoteResourceDownloadOperation *anOperation) {
		[nrSelf configureRemoteResourceDownloadOperation:anOperation];
	};

	NSDate *launchFinishDate = [NSDate date];

	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		(id)kCFBooleanTrue, [[UIApplication sharedApplication] crashReportingEnabledUserDefaultsKey],
	nil]];
	
	[[UIApplication sharedApplication] setCrashReportRecipients:[NSArray arrayWithObjects:
		@"Evadne Wu <evadne.wu@waveface.com>",
		@"Vincent Huang <vincent.huang@waveface.com>",
		@"Jamie Sa <jamie@waveface.com",
		@"Mineral <redmine@waveface.com",
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
		
		__block UIViewController *presentedViewController = [[(UIViewController *)[NSClassFromString(rootViewControllerClassName) alloc] init] autorelease];
		BOOL needsTransition = !!self.window.rootViewController && ([[NSDate date] timeIntervalSinceDate:launchFinishDate] > 2);
		
		self.window.rootViewController = (( ^ {
		
			__block WANavigationController *navController = [WANavigationController alloc];
			
			if (UIUserInterfaceIdiomPhone == UI_USER_INTERFACE_IDIOM()) {
					navController = [[navController initWithRootViewController:presentedViewController] autorelease];
					navController.navigationBar.tintColor = [UIColor colorWithRed:216.0/255.0 green:93.0/255.0 blue:3.0/255.0 alpha:1.0];
					return navController;
			}
			
			navController = [[((^ {
				
				NSKeyedUnarchiver *unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:
					[NSKeyedArchiver archivedDataWithRootObject:
						[[navController initWithRootViewController:
							[[[UIViewController alloc] init] autorelease]
						] autorelease]
					]] autorelease];
				
				[unarchiver setClass:[WANavigationBar class] forClassName:@"UINavigationBar"];
				
				return unarchiver;
				
			})()) decodeObjectForKey:@"root"] initWithRootViewController:presentedViewController];
			
			
			navController.onViewDidLoad = ^ (WANavigationController *self) {
				self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternThickShrunkPaper"]];
			};
			
			if ([navController isViewLoaded])
				navController.onViewDidLoad(navController);
			
			((WANavigationBar *)navController.navigationBar).backgroundView = [WANavigationBar defaultGradientBackgroundView];
			
			return navController;
			
		})());
		
		if ([presentedViewController conformsToProtocol:@protocol(WAApplicationRootViewController)])
			[(id<WAApplicationRootViewController>)presentedViewController setDelegate:self];
				
		if (needsTransition) {
			
			CATransition *transition = [CATransition animation];
			transition.type = kCATransitionFade;
			transition.duration = 0.3f;
			transition.fillMode = kCAFillModeForwards;
			transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			transition.removedOnCompletion = YES;
			
			[self.window.layer addAnimation:transition forKey:kCATransition];
		
		}
		
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:needsTransition];
		
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

	NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserIdentifier];
	NSData *lastAuthenticatedUserTokenKeychainItemData = [[NSUserDefaults standardUserDefaults] dataForKey:kWALastAuthenticatedUserTokenKeychainItem];
	NSString *lastAuthenticatedUserPrimaryGroupIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];
	IRKeychainAbstractItem *lastAuthenticatedUserTokenKeychainItem = nil;
	
	if (!lastAuthenticatedUserTokenKeychainItem) {
		if (lastAuthenticatedUserTokenKeychainItemData) {
			lastAuthenticatedUserTokenKeychainItem = [NSKeyedUnarchiver unarchiveObjectWithData:lastAuthenticatedUserTokenKeychainItemData];
		}
	}
	
	BOOL authenticationInformationSufficient = (lastAuthenticatedUserTokenKeychainItem.secret) && lastAuthenticatedUserIdentifier;
	
	if (authenticationInformationSufficient) {
	
		if (lastAuthenticatedUserIdentifier)
			[WARemoteInterface sharedInterface].userIdentifier = lastAuthenticatedUserIdentifier;
		
		if (lastAuthenticatedUserTokenKeychainItem.secretString)
			[WARemoteInterface sharedInterface].userToken = lastAuthenticatedUserTokenKeychainItem.secretString;
		
		if (lastAuthenticatedUserPrimaryGroupIdentifier)
			[WARemoteInterface sharedInterface].primaryGroupIdentifier = lastAuthenticatedUserPrimaryGroupIdentifier;
		
	}
	
	return authenticationInformationSufficient;

}

- (void) presentAuthenticationRequestRemovingPriorData:(BOOL)erasesExistingAuthenticationInformation {

	if (erasesExistingAuthenticationInformation) {
	
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kWALastAuthenticatedUserTokenKeychainItem];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kWALastAuthenticatedUserIdentifier];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];
		[[NSUserDefaults standardUserDefaults] synchronize];
	
	}

	NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserIdentifier];
	NSData *lastAuthenticatedUserTokenKeychainItemData = [[NSUserDefaults standardUserDefaults] dataForKey:kWALastAuthenticatedUserTokenKeychainItem];
	NSString *lastAuthenticatedUserPrimaryGroupIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];
	IRKeychainAbstractItem *lastAuthenticatedUserTokenKeychainItem = nil;
	
	if (!lastAuthenticatedUserTokenKeychainItem) {
		if (lastAuthenticatedUserTokenKeychainItemData) {
			lastAuthenticatedUserTokenKeychainItem = [NSKeyedUnarchiver unarchiveObjectWithData:lastAuthenticatedUserTokenKeychainItemData];
		}
	}
	
	BOOL authenticationInformationSufficient = (lastAuthenticatedUserTokenKeychainItem.secret) && lastAuthenticatedUserIdentifier;
	
	if (!lastAuthenticatedUserTokenKeychainItem)
		lastAuthenticatedUserTokenKeychainItem = [[[IRKeychainInternetPasswordItem alloc] initWithIdentifier:@"com.waveface.wammer"] autorelease];
	
	void (^writeCredentials)(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) = ^ (NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
	
		lastAuthenticatedUserTokenKeychainItem.secretString = userToken;
		[lastAuthenticatedUserTokenKeychainItem synchronize];
		
		NSData *archivedItemData = [NSKeyedArchiver archivedDataWithRootObject:lastAuthenticatedUserTokenKeychainItem];
		
		[[NSUserDefaults standardUserDefaults] setObject:archivedItemData forKey:kWALastAuthenticatedUserTokenKeychainItem];
		[[NSUserDefaults standardUserDefaults] setObject:userIdentifier forKey:kWALastAuthenticatedUserIdentifier];
		[[NSUserDefaults standardUserDefaults] setObject:primaryGroupIdentifier forKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[WARemoteInterface sharedInterface].userIdentifier = userIdentifier;
		[WARemoteInterface sharedInterface].userToken = userToken;
		[WARemoteInterface sharedInterface].primaryGroupIdentifier = primaryGroupIdentifier;
	
	};
	
	
	if (authenticationInformationSufficient) {
	
		[WARemoteInterface sharedInterface].userIdentifier = lastAuthenticatedUserIdentifier;
		[WARemoteInterface sharedInterface].userToken = lastAuthenticatedUserTokenKeychainItem.secretString;
		[WARemoteInterface sharedInterface].primaryGroupIdentifier = lastAuthenticatedUserPrimaryGroupIdentifier;
		
		//	We don’t have to validate this again since the token never expires
	
	}
	
	if (!authenticationInformationSufficient) {
	
		[WARemoteInterface sharedInterface].userIdentifier = nil;
		[WARemoteInterface sharedInterface].userToken = nil;
		[WARemoteInterface sharedInterface].primaryGroupIdentifier = nil;
	
		__block WAAuthenticationRequestViewController *authRequestVC = [WAAuthenticationRequestViewController controllerWithCompletion: ^ (WAAuthenticationRequestViewController *self, NSError *anError) {
		
				if (anError) {
				
					//	Help
					
					NSString *alertTitle = @"Can’t authenticate";
					NSString *alertText = [NSString stringWithFormat:
						@"Wammer has trouble authenticating your account: “%@”. \n\n You can reset your password, or register a new account.",
						[anError localizedDescription]
					];
					
					IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:[IRAction actionWithTitle:@"Cancel" block:^{
						
					}] otherActions:[NSArray arrayWithObjects:
					
						[IRAction actionWithTitle:@"Reset Password" block: ^ {
						
							//	?
						
						}],
						
						[IRAction actionWithTitle:@"Register" block: ^ {
						
							__block WARegisterRequestViewController *registerRequestVC = [WARegisterRequestViewController controllerWithCompletion:^(WARegisterRequestViewController *self, NSError *error) {
							
								if (error) {
									
									NSString *alertTitle = @"Error Registering Account";
									NSString *alertText = [NSString stringWithFormat:
										@"Wammer has trouble registering your account: “%@”. \n\n Please try registrating later.",
										[error localizedDescription]
									];
									
									[[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:nil otherActions:[NSArray arrayWithObjects:
									
										[IRAction actionWithTitle:@"OK" block:nil],
									
									nil]] show];
									
									return;
								
								}
							
								authRequestVC.username = self.username;
								authRequestVC.password = self.password;
								[authRequestVC.tableView reloadData];
								[authRequestVC.navigationController popToViewController:authRequestVC animated:YES];

								
							}];
						
							registerRequestVC.username = authRequestVC.username;
							registerRequestVC.password = authRequestVC.password;
							
							[authRequestVC.navigationController pushViewController:registerRequestVC animated:YES];
						
						}],
					
					nil]];
					
					[alertView show];
					
					return;
				
				}
		
				writeCredentials([WARemoteInterface sharedInterface].userIdentifier, [WARemoteInterface sharedInterface].userToken, [WARemoteInterface sharedInterface].primaryGroupIdentifier);
				
				[[WADataStore defaultStore] updateCurrentUserOnSuccess: ^ {

					dispatch_async(dispatch_get_main_queue(), ^{
						
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
						
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0f * NSEC_PER_SEC), dispatch_get_main_queue(), operations);
					
					});
					
				} onFailure: ^ {
				
					dispatch_async(dispatch_get_main_queue(), ^{

						[IRAlertView alertViewWithTitle:@"Error Retrieving User Information" message:@"Unable to retrieve user metadata." cancelAction:nil otherActions:[NSArray arrayWithObjects:
						
							[IRAction actionWithTitle:@"Okay" block:nil],
						
						nil]];
					
					});
					
				}];
				
		}];
		
		WANavigationController *authRequestWrappingVC = [[[WANavigationController alloc] initWithRootViewController:authRequestVC] autorelease];
		authRequestWrappingVC.modalPresentationStyle = UIModalPresentationFormSheet;
		authRequestWrappingVC.disablesAutomaticKeyboardDismissal = YES;
        
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
				[fullscreenBaseVC presentModalViewController:authRequestWrappingVC animated:YES];
				
				break;
			
			}
			
			case UIUserInterfaceIdiomPhone:
			default: {
			
				[self.window.rootViewController presentModalViewController:authRequestWrappingVC animated:NO];
				break;
				
			}
		
		}
	
	}

}

#pragma mark - Setup View Controller and Delegate

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

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didBeginDownloadingResourceAtURL:(NSURL *)anURL {

	[self beginNetworkActivity];

}

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFinishDownloadingResourceAtURL:(NSURL *)anURL {

	[self endNetworkActivity];

}

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFailDownloadingResourceAtURL:(NSURL *)anURL {

	[self endNetworkActivity];

}

- (NSURL *) remoteResourcesManager:(IRRemoteResourcesManager *)manager invokedURLForResourceAtURL:(NSURL *)givenURL {

	if ([[givenURL host] isEqualToString:@"invalid.local"]) {
	
		NSURL *currentBaseURL = [WARemoteInterface sharedInterface].engine.context.baseURL;
		NSString *replacementHost = [currentBaseURL host];
		NSNumber *replacementPort = [currentBaseURL port];
		
		NSString *constructedURLString = [[NSArray arrayWithObjects:
			
			[givenURL scheme] ? [[givenURL scheme] stringByAppendingString:@"://"]: @"",
			replacementHost,	//	[givenURL host] ? [givenURL host] : @"",
			replacementPort ? [@":" stringByAppendingString:[replacementPort stringValue]] : @"",
			[givenURL path] ? [givenURL path] : @"",
			[givenURL query] ? [@"?" stringByAppendingString:[givenURL query]] : @"",
			[givenURL fragment] ? [@"#" stringByAppendingString:[givenURL fragment]] : @"",
			
		nil] componentsJoinedByString:@""];
		
		NSURL *constructedURL = [NSURL URLWithString:constructedURLString];
		
		return constructedURL;
		
	}
	
	return givenURL;

}

- (void) configureRemoteResourceDownloadOperation:(IRRemoteResourceDownloadOperation *)anOperation {

	NSURLConnection *originalConnection = [anOperation underlyingConnection];
	NSMutableURLRequest *originalRequest = [anOperation underlyingRequest];
	
	NSURLRequest *transformedRequest = [[WARemoteInterface sharedInterface].engine transformedRequestWithRequest:originalRequest usingMethodName:@"loadedResource"];
		
	originalRequest.URL = transformedRequest.URL;
	originalRequest.allHTTPHeaderFields = transformedRequest.allHTTPHeaderFields;
	originalRequest.HTTPMethod = transformedRequest.HTTPMethod;
	originalRequest.HTTPBodyStream = transformedRequest.HTTPBodyStream;
	originalRequest.HTTPBody = transformedRequest.HTTPBody;

}

@end
