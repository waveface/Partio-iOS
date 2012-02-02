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
  return [[NSUserDefaults standardUserDefaults] boolForKey:kWAAdvancedFeaturesEnabled];
};


NSString * const kWARemoteEndpointURL = @"WARemoteEndpointURL";
NSString * const kWARemoteEndpointVersion = @"WARemoteEndpointVersion";
NSString * const kWARemoteEndpointCurrentVersion = @"WARemoteEndpointCurrentVersion";
NSString * const kWALastAuthenticatedUserTokenKeychainItem = @"WALastAuthenticatedUserTokenKeychainItem";
NSString * const kWALastAuthenticatedUserPrimaryGroupIdentifier = @"WALastAuthenticatedUserPrimaryGroupIdentifier";
NSString * const kWALastAuthenticatedUserIdentifier = @"WALastAuthenticatedUserIdentifier";
NSString * const kWAUserRegistrationUsesWebVersion = @"WAUserRegistrationUsesWebVersion";
NSString * const kWAUserRegistrationEndpointURL = @"WAUserRegistrationEndpointURL";
NSString * const kWAUserRequiresReauthentication = @"WAUserRequiresReauthentication";
NSString * const kWAUserPasswordResetEndpointURL = @"WAUserPasswordResetEndpointURL";
NSString * const kWAAlwaysAllowExpensiveRemoteOperations = @"WAAlwaysAllowExpensiveRemoteOperations";
NSString * const kWAAlwaysDenyExpensiveRemoteOperations = @"WAAlwaysDenyExpensiveRemoteOperations";
NSString * const kWADebugAutologinUserIdentifier = @"WADebugAutologinUserIdentifier";
NSString * const kWADebugAutologinUserPassword = @"WADebugAutologinUserPassword";

NSString * const kWADebugLastScanSyncBezelsVisible = @"WADebugLastScanSyncBezelsVisible";
NSString * const kWADebugUsesDiscreteArticleFlip = @"WADebugUsesDiscreteArticleFlip";
NSString * const kWADebugPersistentStoreName = @"WADebugPersistentStoreName";

NSString * const kWACompositionSessionRequestedNotification = @"WACompositionSessionRequestedNotification";
NSString * const kWAApplicationDidReceiveRemoteURLNotification = @"WAApplicationDidReceiveRemoteURLNotification";
NSString * const kWARemoteInterfaceReachableHostsDidChangeNotification = @"WARemoteInterfaceReachableHostsDidChangeNotification";
NSString * const kWARemoteInterfaceDidObserveAuthenticationFailureNotification = @"WARemoteInterfaceDidObserveAuthenticationFailureNotification";
NSString * const kWASettingsDidRequestActionNotification = @"kWASettingsDidRequestActionNotification";

NSString * const kWATestflightTeamToken = @"2e0589c9a03560bfeb93e215fdd9cbbb_MTg2ODAyMDExLTA5LTIyIDA0OjM4OjI1LjMzNTEyNg";
NSString * const kWACrashlyticsAPIKey = @"d79b0f823e42fdf1cdeb7e988a8453032fd85169";

NSString * const kWARemoteEndpointApplicationKeyPhone = @"ca5c3c5c-287d-5805-93c1-a6c2cbf9977c";
NSString * const kWARemoteEndpointApplicationKeyPad = @"ba15e628-44e6-51bc-8146-0611fdfa130b";
NSString * const kWARemoteEndpointApplicationKeyMac = @"ba15e628-44e6-51bc-8146-0611fdfa130b";

NSString * const kWACallbackActionDidFinishUserRegistration = @"didFinishUserRegistration";
NSString * const kWACallbackActionSetAdvancedFeaturesEnabled = @"showMeTheMoney";
NSString * const kWACallbackActionSetRemoteEndpointURL = @"setRemoteEndpointURL";
NSString * const kWACallbackActionSetUserRegistrationEndpointURL = @"setUserRegistrationEndpointURL";
NSString * const kWACallbackActionSetUserPasswordResetEndpointURL = @"setUserPasswordResetEndpointURL";

NSString * const kWAUserStorageInfo = @"UserStoragesInfo";

void WARegisterUserDefaults () {

	[[NSUserDefaults standardUserDefaults] registerDefaults:WAPresetDefaults()];

}

NSDictionary * WAPresetDefaults () {

	NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"WADefaults" withExtension:@"plist"];
	NSData *defaultsData = [NSData dataWithContentsOfMappedFile:[defaultsURL path]];
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
	
	NSString *uuid = [NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, uuidRef)) autorelease];
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

	NSMutableDictionary *sentUserInfo = [[userInfo mutableCopy] autorelease];
	if (!sentUserInfo)
		sentUserInfo = [NSMutableDictionary dictionary];
	
	if (eventTitle)
		[sentUserInfo setObject:eventTitle forKey:kWAAppEventTitle];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kWAAppEventNotification object:nil userInfo:sentUserInfo];

}
