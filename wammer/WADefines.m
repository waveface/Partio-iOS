//
//  WADefines.m
//  wammer
//
//  Created by Evadne Wu on 10/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import <sys/sysctl.h>

NSString * const kWAAdvancedFeaturesEnabled = @"WAAdvancedFeaturesEnabled";

BOOL WAAdvancedFeaturesEnabled (void) {

#if TARGET_IPHONE_SIMULATOR

	return YES;

#endif

  return [[NSUserDefaults standardUserDefaults] boolForKey:kWAAdvancedFeaturesEnabled];
	
};


NSString * const kWARemoteEndpointURL = @"WARemoteEndpointURL";
NSString * const kWARemoteEndpointVersion = @"WARemoteEndpointVersion";
NSString * const kWARemoteEndpointCurrentVersion = @"WARemoteEndpointCurrentVersion";
NSString * const kWARemoteEndpointWebURL = @"WARemoteEndpointWebURL";
NSString * const kWALastAuthenticatedUserTokenKeychainItem = @"WALastAuthenticatedUserTokenKeychainItem";
NSString * const kWALastAuthenticatedUserPrimaryGroupIdentifier = @"WALastAuthenticatedUserPrimaryGroupIdentifier";
NSString * const kWALastAuthenticatedUserIdentifier = @"WALastAuthenticatedUserIdentifier";
NSString * const kWAUserRegistrationUsesWebVersion = @"WAUserRegistrationUsesWebVersion";
NSString * const kWAUserRegistrationEndpointURL = @"WAUserRegistrationEndpointURL";
NSString * const kWAUserFacebookAuthenticationEndpointURL = @"WAUserFacebookAuthenticationEndpointURL";
NSString * const kWAUserRequiresReauthentication = @"WAUserRequiresReauthentication";
NSString * const kWAUserPasswordResetEndpointURL = @"WAUserPasswordResetEndpointURL";
NSString * const kWAAlwaysAllowExpensiveRemoteOperations = @"WAAlwaysAllowExpensiveRemoteOperations";
NSString * const kWAAlwaysDenyExpensiveRemoteOperations = @"WAAlwaysDenyExpensiveRemoteOperations";
NSString * const kWADebugAutologinUserIdentifier = @"WADebugAutologinUserIdentifier";
NSString * const kWADebugAutologinUserPassword = @"WADebugAutologinUserPassword";

NSString * const kWADebugLastScanSyncBezelsVisible = @"WADebugLastScanSyncBezelsVisible";
NSString * const kWADebugPersistentStoreName = @"WADebugPersistentStoreName";

NSString * const kWACompositionSessionRequestedNotification = @"WACompositionSessionRequestedNotification";
NSString * const kWAApplicationDidReceiveRemoteURLNotification = @"WAApplicationDidReceiveRemoteURLNotification";
NSString * const kWARemoteInterfaceDidObserveAuthenticationFailureNotification = @"WARemoteInterfaceDidObserveAuthenticationFailureNotification";
NSString * const kWASettingsDidRequestActionNotification = @"kWASettingsDidRequestActionNotification";
NSString * const kWACoreDataReinitialization = @"kWACoreDataReinitialization";

NSString * const kWAFacebookDidLoginNotification = @"kWAFacebookDidLoginNotification";
NSString * const kWAFacebookAppID = @"WAFacebookAppID";
NSString * const kWAFacebookTokenKey = @"FBAccessTokenKey";
NSString * const kWAFacebookExpirationDateKey = @"FBExpirationDateKey";

NSString * const kWATwitterConsumerKey = @"WATwitterConsumerKey";
NSString * const kWATwitterConsumerSecret = @"WATwitterConsumerSecret";

NSString * const kWACrashlyticsAPIKey = @"d79b0f823e42fdf1cdeb7e988a8453032fd85169";
NSString * const kWAGoogleAnalyticsAccountID = @"UA-27817516-3";
NSInteger  const kWAGoogleAnalyticsDispatchInterval = 10;
			
NSString * const kWARemoteEndpointApplicationKeyPhone = @"6d095eaa-73f8-5087-9797-f5633979045b";
NSString * const kWARemoteEndpointApplicationKeyPad = @"ba15e628-44e6-51bc-8146-0611fdfa130b";
NSString * const kWARemoteEndpointApplicationKeyMac = @"ba15e628-44e6-51bc-8146-0611fdfa130b";

NSString * const WAFeedbackRecipient = @"WAFeedbackRecipient";
NSString * const WAStreamFeaturesURL = @"WAStreamFeaturesURL";

NSString * const kWACallbackActionDidFinishUserRegistration = @"didFinishUserRegistration";
NSString * const kWACallbackActionSetAdvancedFeaturesEnabled = @"showMeTheMoney";
NSString * const kWACallbackActionSetRemoteEndpointURL = @"setRemoteEndpointURL";
NSString * const kWACallbackActionSetUserRegistrationEndpointURL = @"setUserRegistrationEndpointURL";
NSString * const kWACallbackActionSetUserPasswordResetEndpointURL = @"setUserPasswordResetEndpointURL";

NSString * const kWAPhotoImportEnabled = @"WAPhotoImportEnabled";
NSString * const kWAFirstUseVisited = @"kWAFirstUseVisited";
NSString * const kWAUseCellularEnabled = @"WAUseCellularEnabled";
NSString * const kWABackupFilesToCloudEnabled = @"WABackupFilesToCloudEnabled";
NSString * const kWABusinessPlan = @"WABusinessPlan";

NSString * const kWASNSFacebookConnectEnabled = @"WAFacebookConnectEnabled";
NSString * const kWASNSGoogleConnectEnabled = @"WAGoogleConnectEnabled";
NSString * const kWASNSTwitterConnectEnabled = @"WATwitterConnectEnabled";
NSString * const kWASNSFoursquareConnectEnabled = @"WAFoursquareConnectEnabled";

NSString * const kWAFirstArticleFetched = @"WAFirstArticleSynced";
NSString * const kWAAllCollectionsFetchOnce = @"WAAllCollectionsFetchOnce";
NSString * const kWARemoteInterfaceDidFetchArticleNotification = @"WARemoteInterfaceDidFetchArticleNotification";


void WARegisterUserDefaults () {

	[[NSUserDefaults standardUserDefaults] registerDefaults:WAPresetDefaults()];

}

NSDictionary * WAPresetDefaults () {

#if DEBUG
	NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"WADefaults.develop" withExtension:@"plist"];
#elif STREAM_BETA
	NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"WADefaults.staging" withExtension:@"plist"]; // Production and Beta
#else
	NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"WADefaults" withExtension:@"plist"]; // Production and Beta
#endif
	NSData *defaultsData = [NSData dataWithContentsOfFile:[defaultsURL path] options:NSDataReadingMappedIfSafe error:nil];
	NSDictionary *defaultsObject = [NSPropertyListSerialization propertyListFromData:defaultsData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
	
	return defaultsObject;

}


BOOL WAApplicationHasDebuggerAttached (void) {

	int mib[4];
	size_t bufSize = 0;
	int local_error = 0;
	struct kinfo_proc kp;

	mib[0] = CTL_KERN;
	mib[1] = KERN_PROC;
	mib[2] = KERN_PROC_PID;
	mib[3] = getpid();

	bufSize = sizeof (kp);
	if ((local_error = sysctl(mib, 4, &kp, &bufSize, NULL, 0)) < 0) {
		NSLog(@"Failure calling sysctl");
		return NO;
	}
	
	if (kp.kp_proc.p_flag & P_TRACED)
		return YES;
			
	return NO;

}


NSString * const kWACurrentGeneratedDeviceIdentifier = @"WACurrentGeneratedDeviceIdentifier";

BOOL WADeviceIdentifierReset (void) {

	CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
	if (!uuidRef)
    return NO;
	
	NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
	CFRelease(uuidRef);

  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWACurrentGeneratedDeviceIdentifier];
  [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:kWACurrentGeneratedDeviceIdentifier];
  
  return [[NSUserDefaults standardUserDefaults] synchronize];

}


NSString * WADeviceIdentifier (void) {

  NSString *returnedString = [[NSUserDefaults standardUserDefaults] stringForKey:kWACurrentGeneratedDeviceIdentifier];
  if (returnedString)
    return returnedString;

  if (WADeviceIdentifierReset())
    return WADeviceIdentifier();

  return nil;

}

NSString * const kWAAppEventNotification = @"WAAppEventNotification";
NSString * const kWAAppEventTitle = @"WAAppEventTitle";

void WAPostAppEvent (NSString *eventTitle, NSDictionary *userInfo) {

	NSMutableDictionary *sentUserInfo = [userInfo mutableCopy];
	if (!sentUserInfo)
		sentUserInfo = [NSMutableDictionary dictionary];
	
	if (eventTitle)
		[sentUserInfo setObject:eventTitle forKey:kWAAppEventTitle];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kWAAppEventNotification object:nil userInfo:sentUserInfo];

}

NSString * const kWADucklingsEnabled = @"WADucklingsEnabled";
BOOL WADucklingsEnabled (void) {

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kWADucklingsEnabled])
		return YES;
	
	return NO;

}
