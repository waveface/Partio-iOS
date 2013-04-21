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
#import "WAFetchManager.h"
#import "WAStatusBar.h"

#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WANavigationController.h"
#import "WAApplicationRootViewControllerDelegate.h"
#import "WATimelineViewController.h"
#import "WAUserInfoViewController.h"
#import "WAOverlayBezel.h"

#import "WAPartioNavigationController.h"
#import "WASharedEventViewController.h"
#import "WASpotlightSlideFlowLayout.h"
#import "WAPhotoHighlightsViewController.h"
#import "WAPartioFirstUseViewController.h"
#import "WAFacebookLoginViewController.h"

#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"

#import "IASKSettingsReader.h"
#import	"DCIntrospect.h"

#import <FacebookSDK/FacebookSDK.h>
#import <FacebookSDK/NSError+FBError.h>
#import <GoogleMaps/GoogleMaps.h>

#import "WAWelcomeViewController.h"

#import "IIViewDeckController.h"
#import "WASlidingMenuViewController.h"
#import "WADayViewController.h"
#import "WACacheManager.h"

#import "UIViewController+WAAdditions.h"

#if ENABLE_PONYDEBUG
#import "PonyDebugger/PDDebugger.h"
#endif

#import "WAFilterPickerViewController.h"
#import "WAFirstUseViewController.h"

#import "TestFlight.h"
#import "WAPhotoStreamViewController.h"

#define MR_SHORTHAND
#import "CoreData+MagicalRecord.h"

static NSString *const kTrackingId = @"UA-27817516-8";

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

- (BOOL) shouldAutorotate {
  
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
@property (nonatomic, strong) WACacheManager *cacheManager;
@property (nonatomic, strong) WASyncManager *syncManager;
@property (nonatomic, strong) WAFetchManager *fetchManager;
@property (nonatomic, strong) WASlidingMenuViewController *slidingMenu;
@property (nonatomic, strong) WAStatusBar *statusBar;

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
      
      [TestFlight takeOff:@"fc829e58-110d-4cc7-9ee0-39a3dd54e6c9"];
      
      id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kWAAppEventNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        
        NSString *eventTitle = [note userInfo][kWAAppEventTitle];
        [TestFlight passCheckpoint:eventTitle];
        
      }];
      
      objc_setAssociatedObject([TestFlight class], &kWAAppEventNotification, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      
    });
    
  }
  
  AVAudioSession * const audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
  [audioSession setActive:YES error:nil];
  
  WADefaultBarButtonInitialize();
  
}

- (void) bootstrapWhenUserLogin {
  
  WARemoteInterface *ri = [WARemoteInterface sharedInterface];
  if (ri.userToken) {
    [self updateCurrentCredentialsWithUserIdentifier:ri.userIdentifier token:ri.userToken primaryGroup:ri.primaryGroupIdentifier];
    [self bootstrapPersistentStoreWithUserIdentifier:ri.userIdentifier];
    [self cacheManager];
    self.fetchManager = [[WAFetchManager alloc] init];
    self.syncManager = [[WASyncManager alloc] init];
    [self initStatusBar];
    
    [self subscribeRemoteNotification];
  }
  
}

extern CFAbsoluteTime StartTime;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  // Init the GAITracker first, ref: https://developers.google.com/analytics/devguides/collection/ios/v2/#initialize
  // [GAI sharedInstance].debug = YES;
  [GAI sharedInstance].dispatchInterval = 120;
  [GAI sharedInstance].trackUncaughtExceptions = YES;
  [[GAI sharedInstance] trackerWithTrackingId:kTrackingId];
  
  [GMSServices provideAPIKey:@"AIzaSyAyGVeC0T7mPhQJjiKk7GVj8Z2Wmxpas5s"];
  
  [self bootstrap];
  
//  WADefaultAppearance();
  WAPartioDefaultAppearance();
  
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor colorWithRed:0.87 green:0.87 blue:0.84 alpha:1.0];
  
  [self.window makeKeyAndVisible];
  
  if ([[NSUserDefaults standardUserDefaults] stringForKey:kWADebugPersistentStoreName]) {
    
    NSString *identifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWADebugPersistentStoreName];
    [self bootstrapPersistentStoreWithUserIdentifier:identifier];
    
    [self recreateViewHierarchy];
    
  } else if (![self hasAuthenticationData]) {
  
    [self handlePartioAuthRequest];
//    [self applicationRootViewControllerDidRequestReauthentication:nil];
    
  } else {
    
    NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserIdentifier];
    
    if (lastAuthenticatedUserIdentifier)
      [self bootstrapPersistentStoreWithUserIdentifier:lastAuthenticatedUserIdentifier];
    
    [self recreateViewHierarchy];
    
  }
  
  [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Application" withAction:@"Launched" withLabel:nil withValue:@0];
  
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
  
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#pragma clang pop
#endif
  
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [Crashlytics startWithAPIKey:kWACrashlyticsAPIKey];
    WAUser *user = [[WADataStore defaultStore] mainUserInContext:[[WADataStore defaultStore] defaultAutoUpdatedMOC]];
    [Crashlytics setUserIdentifier:user.identifier];
    [Crashlytics setUserEmail:user.email];
    [Crashlytics setUserName:user.nickname];
  });
  
  dispatch_async(dispatch_get_main_queue(), ^{
    NSLog(@"Stream Launched in %0.2f seconds on %@.", CFAbsoluteTimeGetCurrent() - StartTime, [UIDevice currentDevice].model);
  });
  
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
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [wSelf hideStatusBarIfNecessary];
  });
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    NSLog(@"Enter background, wait until sync operations finished");
    [wSelf.syncManager waitUntilFinished];
    NSLog(@"All sync operations are finished");
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
    
  self.slidingMenu = nil;
  
  UIViewController *rootVC = self.window.rootViewController;
  
  [rootVC zapModal];
  
  self.window.rootViewController = [[WALoginBackgroundViewController alloc] init];
  
}

- (void) initStatusBar {
  
  if (self.syncManager) {
    [self.syncManager addObserver:self
                       forKeyPath:@"syncedFilesCount"
                          options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                          context:nil];
  }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"syncedFilesCount"]) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

      if (self.syncManager.isSyncing) {
  
        if (!self.statusBar) {
          self.statusBar = [[WAStatusBar alloc] initWithFrame:CGRectZero];
        }
        
        if (self.syncManager.needingSyncFilesCount) {
          [self.statusBar showPhotoSyncingWithSyncedFilesCount:self.syncManager.syncedFilesCount
                                         needingSyncFilesCount:self.syncManager.needingSyncFilesCount];
          [self.statusBar startDataExchangeAnimation];
        } else {
          [self.statusBar showSyncCompleteWithDissmissBlock:^{
            self.statusBar = nil;
          }];
        }
      
      } else {
        [self.statusBar showSyncCompleteWithDissmissBlock:^{
          self.statusBar = nil;
        }];
      }
    }];
    
  }
}

- (void) hideStatusBarIfNecessary {
  
  if (self.syncManager) {
    [self.syncManager removeObserver:self forKeyPath:@"syncedFilesCount"];
  }
  if (self.statusBar) {
    self.statusBar = nil;
  }
  
}

- (void) recreateViewHierarchy {
  
  [[IRRemoteResourcesManager sharedManager].queue cancelAllOperations];
  
//  self.slidingMenu = [[WASlidingMenuViewController alloc] init];
//  self.slidingMenu.delegate = self;
//  WANavigationController *navSlide = [[WANavigationController alloc] initWithRootViewController:self.slidingMenu];
//  navSlide.navigationBarHidden = YES;
//  
//  NSParameterAssert(self.syncManager);
//  
//  IIViewDeckController *viewDeckController = [[IIViewDeckController alloc] initWithCenterViewController:[WASlidingMenuViewController dayViewControllerForViewStyle:WAEventsViewStyle]
//                                                                                     leftViewController:navSlide];
//  viewDeckController.view.backgroundColor = [UIColor blackColor];
//  
//  if (isPad() && (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])))
//    viewDeckController.leftLedge = self.window.frame.size.height - [WASlidingMenuViewController ledgeSize];
//  else
//    viewDeckController.leftLedge = self.window.frame.size.width - [WASlidingMenuViewController ledgeSize];
//  
//  viewDeckController.rotationBehavior = IIViewDeckRotationKeepsLedgeSizes;
//  //			viewDeckController.animationBehavior = IIViewDeckAnimationPullIn;
//  viewDeckController.panningMode = IIViewDeckNoPanning;
//  [viewDeckController setWantsFullScreenLayout:YES];
//  viewDeckController.delegate = self.slidingMenu;
//  viewDeckController.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
  
  __weak WAAppDelegate_iOS *wSelf = self;
  
  if (![FBSession activeSession].isOpen) {
    WAFacebookLoginViewController *fbLoginVC = [[WAFacebookLoginViewController alloc] initWithCompletionHandler:^(NSError *error) {
          
      if (error) {
        NSLog(@"failed to login facebook for error: %@", error);
        
        IRAction *cancelAction = [IRAction actionWithTitle:@"Dismiss" block:^{
          [wSelf handlePartioAuthRequest];
        }];
        IRAlertView *alertView = [IRAlertView alertViewWithTitle:@"Oops! Something wrong" message:@"Unable to login. Please check your networking adn try again." cancelAction:cancelAction otherActions:nil];
        [alertView show];
        
      } else {

        [wSelf cacheManager];
        [wSelf bootstrapWhenUserLogin];

        WASpotlightSlideFlowLayout *flowlayout = [[WASpotlightSlideFlowLayout alloc] init];
        WASharedEventViewController *sharedEventsVC = [[WASharedEventViewController alloc] initWithCollectionViewLayout:flowlayout];
        WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:sharedEventsVC];
        wSelf.window.rootViewController = navVC;
      }
    
    }];
    self.window.rootViewController = fbLoginVC;
  } else {

    [self bootstrapWhenUserLogin];

    WASpotlightSlideFlowLayout *flowlayout = [[WASpotlightSlideFlowLayout alloc] init];
    WASharedEventViewController *sharedEventsVC = [[WASharedEventViewController alloc] initWithCollectionViewLayout:flowlayout];
    WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:sharedEventsVC];
    self.window.rootViewController = navVC;
    
  }
  
  
  UIViewController *vc = self.window.rootViewController;
  
  [vc willRotateToInterfaceOrientation:vc.interfaceOrientation duration:0];
  [vc willAnimateRotationToInterfaceOrientation:vc.interfaceOrientation duration:0];
  [vc didRotateFromInterfaceOrientation:vc.interfaceOrientation];
  
  
}

- (void) logout {
  
  [self.syncManager cancelWithRecovery];
  [self.fetchManager cancelWithRecovery];
  
  self.cacheManager = nil;
  self.syncManager = nil;
  self.fetchManager = nil;
  
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAPhotoImportEnabled];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAFirstUseVisited];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAAllCollectionsFetchOnce];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAFirstArticleFetched];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWASNSFacebookConnectEnabled];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWASNSGoogleConnectEnabled];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWASNSTwitterConnectEnabled];
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWASNSFoursquareConnectEnabled];
  [[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanFree forKey:kWABusinessPlan];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self unsubscribeRemoteNotification];
  
}

- (void) applicationRootViewControllerDidRequestReauthentication:(id<WAApplicationRootViewController>)controller {
  
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
       
       [wSelf.cacheManager clearPurgeableFilesIfNeeded];
       
       // reset monitored hosts
       WARemoteInterface *ri = [WARemoteInterface sharedInterface];
       
       // close websocket if needed
       [ri closeWebSocketConnection];
       
       ri.monitoredHosts = nil;
       [ri performAutomaticRemoteUpdatesNow];
       
       wSelf.fetchManager = [[WAFetchManager alloc] init];
       [wSelf.fetchManager reload];
       wSelf.syncManager = [[WASyncManager alloc] init];
       [wSelf.syncManager reload];
       
     }
                         runningOnboardingProcess:YES];
    
  });
  
}

- (void) handleObservedAuthenticationFailure:(NSNotification *)aNotification {
  
  NSError *error = [aNotification userInfo][@"error"];

  __weak WAAppDelegate_iOS *wSelf = self;
  [self unsubscribeRemoteNotification];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    
    [self presentAuthenticationRequestWithReason:[error localizedDescription]
                            allowingCancellation:NO
                               removingPriorData:YES
                     clearingNavigationHierarchy:YES
                                   onAuthSuccess:^(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier) {
      
                                     [wSelf updateCurrentCredentialsWithUserIdentifier:userIdentifier token:userToken primaryGroup:primaryGroupIdentifier];
                                     [wSelf bootstrapPersistentStoreWithUserIdentifier:userIdentifier];
                                     
                                     [wSelf.cacheManager clearPurgeableFilesIfNeeded];
                                     
                                     // reset monitored hosts
                                     WARemoteInterface *ri = [WARemoteInterface sharedInterface];
                                     
                                     // close websocket if needed
                                     [ri closeWebSocketConnection];
                                     
                                     ri.monitoredHosts = nil;
                                     [ri performAutomaticRemoteUpdatesNow];
                                     
                                     wSelf.fetchManager = [[WAFetchManager alloc] init];
                                     [wSelf.fetchManager reload];
                                     wSelf.syncManager = [[WASyncManager alloc] init];
                                     [wSelf.syncManager reload];

      
    } runningOnboardingProcess:NO];
    
  });
  
}

- (void) handleObservedRemoteURLNotification:(NSNotification *)aNotification {
  
  NSString *command = nil;
  NSDictionary *params = nil;
  
  if (!WAIsXCallbackURL([aNotification userInfo][@"url"], &command, &params))
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
      
      [[NSUserDefaults standardUserDefaults] setObject:params[@"url"] forKey:kWARemoteEndpointURL];
      [[NSUserDefaults standardUserDefaults] setObject:params[@"RegistrationUrl"] forKey:kWAUserRegistrationEndpointURL];
      [[NSUserDefaults standardUserDefaults] setObject:params[@"PasswordResetUrl"] forKey:kWAUserPasswordResetEndpointURL];
      [[NSUserDefaults standardUserDefaults] setObject:params[@"FacebookAuthUrl"] forKey:kWAUserFacebookAuthenticationEndpointURL];
      [[NSUserDefaults standardUserDefaults] setObject:params[@"FacebookAppID"] forKey:kWAFacebookAppID];
      [[NSUserDefaults standardUserDefaults] synchronize];
      
      if (nrSelf.alreadyRequestingAuthentication) {
        nrSelf.alreadyRequestingAuthentication = NO;
        [nrSelf clearViewHierarchy];
      }
      
      [nrSelf applicationRootViewControllerDidRequestReauthentication:nil];
      
    };
    
    NSString *alertTitle = @"Switch endpoint to";
    NSString *alertText = params[@"url"];
    
    IRAction *cancelAction = [IRAction actionWithTitle:@"Cancel" block:nil];
    IRAction *confirmAction = [IRAction actionWithTitle:@"Yes, Switch" block:zapAndRequestReauthentication];
    
    [[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:cancelAction otherActions:@[confirmAction]] show];
  }
  
}

- (void) handleIASKSettingsChanged:(NSNotification *)aNotification {
  
  if ([[[aNotification userInfo] allKeys] containsObject:kWAAdvancedFeaturesEnabled])
    [self handleDebugModeToggled];
  
}

- (void) handleIASKSettingsDidRequestAction:(NSNotification *)aNotification {
  
  NSString *action = [aNotification userInfo][@"key"];
  
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
    
    IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:cancelAction otherActions:@[resetAction]];
    
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
    
    alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:nil otherActions:@[okayAndZapAction]];
    
  } else if (![self hasAuthenticationData]) {
    
    //	In the middle of an active auth session, not safe to zap
    
    alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:okayAction otherActions:nil];
    
  } else {
    
    //	Can zap
    
    alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:laterAction otherActions:@[signOutAction]];
    
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
  
  if (zapEverything)
    [self clearViewHierarchy];
  
  if (eraseAuthInfo) {
    [self logout];
    [self removeAuthenticationData];
  }
  
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

- (void) handlePartioAuthRequest {

  __weak WAAppDelegate_iOS *wSelf = self;
  __block WAPartioFirstUseViewController *partioFirstUse = [WAPartioFirstUseViewController firstUseViewControllerWithCompletionBlock:^{

    [self bootstrapWhenUserLogin];
    [partioFirstUse popToRootViewControllerAnimated:NO];
    
    [partioFirstUse dismissViewControllerAnimated:NO completion:^{
      wSelf.window.rootViewController = nil;
      [wSelf recreateViewHierarchy];
    }];
    
    WASpotlightSlideFlowLayout *flowlayout = [[WASpotlightSlideFlowLayout alloc] init];
    WASharedEventViewController *sharedEventsVC = [[WASharedEventViewController alloc] initWithCollectionViewLayout:flowlayout];
    WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:sharedEventsVC];
    wSelf.window.rootViewController = navVC;

  } failure:^(NSError *error) {
    NSLog(@"fail to sign up for error: %@", error);
    IRAction *okAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_OKAY", @"Alert Dismissal Action") block:nil];
    
    IRAlertView *alertView = [IRAlertView alertViewWithTitle:nil message:@"Login failed" cancelAction:okAction otherActions:nil];
    [alertView show];

  }];
  self.window.rootViewController = partioFirstUse;

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
  __weak WAAppDelegate_iOS *wSelf = self;
  __block WAFirstUseViewController *firstUseVC = [WAFirstUseViewController initWithAuthSuccessBlock:^(NSString *token, NSDictionary *userRep, NSArray *groupReps){
    
    NSString *userID = [userRep valueForKeyPath:@"user_id"];
    
    NSString *primaryGroupID = [[[groupReps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
      
      return [[evaluatedObject valueForKeyPath:@"creator_id"] isEqual:userID];
      
    }]] lastObject] valueForKeyPath:@"group_id"];
    
    WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
    
    ri.userIdentifier = userID;
    ri.userToken = token;
    ri.primaryGroupIdentifier = primaryGroupID;
    
    handleAuthSuccess();
    
  } authFailBlock:^(NSError *error) {
    
    NSCParameterAssert(error);
    
    NSString *message = nil;
    if ([error code] == 0x9) {
      message = NSLocalizedString(@"AUTH_ERROR_INVALID_EMAIL_FORMAT", @"Authentication Error Description");
    } else if ([error code] == 0xb) {
      message = NSLocalizedString(@"AUTH_ERROR_INVALID_PWD_FORMAT", @"Authentication Error Description");
    } else if ([error code] == 0x1001) {
      message = NSLocalizedString(@"AUTH_ERROR_INVALID_EMAIL_PWD", @"Authentication Error Description");
    } else if ([error code] == 0x1002) {
      message = NSLocalizedString(@"AUTH_ERROR_ALREADY_REGISTERED", @"Authentication Error Description");
    } else if ([error code] == 0x1004) {
      message = NSLocalizedString(@"AUTH_ERROR_FB_PERMISSION_REQUIRED", @"Require to a valid facebook permission token");
    } else if ([error fberrorShouldNotifyUser]) {
      message = error.fberrorUserMessage;
    } else if ([error fberrorCategory] == FBErrorCategoryUserCancelled) {
      message = NSLocalizedString(@"AUTH_ERROR_FB_CANCEL", @"User cancel facebook app");
    } else if ([error fberrorCategory] == FBErrorCategoryAuthenticationReopenSession) {
      message = NSLocalizedString(@"AUTH_ERROR_FB_REOPEN_REQUIRED", @"Require to login with facebook again");
    } else {
      message = NSLocalizedString(@"AUTH_UNKNOWN_ERROR", @"Unknown Error");
    }
    IRAction *okAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_OKAY", @"Alert Dismissal Action") block:nil];
    
    IRAlertView *alertView = [IRAlertView alertViewWithTitle:nil message:message cancelAction:okAction otherActions:nil];
    [alertView show];
    
  } finishBlock:^{
    
    [firstUseVC popToRootViewControllerAnimated:NO];
    [firstUseVC dismissViewControllerAnimated:NO completion:^{
      wSelf.window.rootViewController = nil;
      [wAppDelegate recreateViewHierarchy];
    }];
    
  }];
  
  switch ([UIDevice currentDevice].userInterfaceIdiom) {
      
    case UIUserInterfaceIdiomPad:
      firstUseVC.modalPresentationStyle = UIModalPresentationFormSheet;
      break;
      
    case UIUserInterfaceIdiomPhone:
      firstUseVC.modalPresentationStyle = UIModalPresentationCurrentContext;
      
  }
  
  [self.window.rootViewController presentViewController:firstUseVC animated:NO completion:nil];
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
    NSDictionary *userInfo = @{@"url": url,
                               @"sourceApplication": sourceApplication,
                               @"annotation": annotation};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWAApplicationDidReceiveRemoteURLNotification object:url userInfo:userInfo];
  }
  
  return YES;
  
}

#pragma mark UIApplication delegates

- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
  
  WAPostAppEvent(@"did-receive-memory-warning", @{});
  
}

- (void)applicationWillTerminate:(UIApplication *)application {
  [FBSession.activeSession close];
  [MagicalRecord cleanUp];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

  [FBSession.activeSession handleDidBecomeActive];
  
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  
  if ([self hasAuthenticationData]) {
    
    [self.cacheManager clearPurgeableFilesIfNeeded];
    if (self.fetchManager && self.syncManager) {
      [self.fetchManager reload];
      [self.syncManager reload];
      
      [self initStatusBar];
    }
  }
  
}

- (WACacheManager *)cacheManager {
  
  @synchronized(self) {
    
    if (!_cacheManager) {
      _cacheManager = [[WACacheManager alloc] init];
      _cacheManager.delegate = self;
      [_cacheManager clearPurgeableFilesIfNeeded];
    }
    
  };
  
  return _cacheManager;
  
}

#pragma mark WACacheManager delegates

- (BOOL)shouldPurgeCachedFile:(WACache *)cache {
  
  return YES;
  
}


- (void) application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration {
  UIViewController *vc = self.window.rootViewController;
  
  if (!vc || ![vc isKindOfClass:[IIViewDeckController class]])
    return;
  
  if (!isPad())
    return;
  
  IIViewDeckController *viewDeck = (IIViewDeckController*)vc;
  if (UIInterfaceOrientationIsLandscape(newStatusBarOrientation)) {
    viewDeck.leftLedge = self.window.frame.size.height - [WASlidingMenuViewController ledgeSize];
  } else {
    viewDeck.leftLedge = self.window.frame.size.width - [WASlidingMenuViewController ledgeSize];
  }
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
