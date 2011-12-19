//
//  WADefines.h
//  wammer
//
//  Created by Evadne Wu on 10/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * const kWAAdvancedFeaturesEnabled;
extern BOOL WAAdvancedFeaturesEnabled (void);

extern NSString * const kWARemoteEndpointURL;
extern NSString * const kWARemoteEndpointVersion;
extern NSString * const kWARemoteEndpointCurrentVersion;
extern NSString * const kWALastAuthenticatedUserTokenKeychainItem;
extern NSString * const kWALastAuthenticatedUserPrimaryGroupIdentifier;
extern NSString * const kWALastAuthenticatedUserIdentifier;
extern NSString * const kWAUserRegistrationUsesWebVersion;
extern NSString * const kWAUserRegistrationEndpointURL;
extern NSString * const kWAUserRequiresReauthentication;
extern NSString * const kWAUserPasswordResetEndpointURL;
extern NSString * const kWAAlwaysAllowExpensiveRemoteOperations;
extern NSString * const kWAAlwaysDenyExpensiveRemoteOperations;
extern NSString * const kWADebugAutologinUserIdentifier;
extern NSString * const kWADebugAutologinUserPassword;
extern NSString * const kWACrashReportRecipients;
extern NSString * const kWADebugLastScanSyncBezelsVisible;

extern NSString * const kWACompositionSessionRequestedNotification;
extern NSString * const kWAApplicationDidReceiveRemoteURLNotification;
extern NSString * const kWARemoteInterfaceReachableHostsDidChangeNotification;
extern NSString * const kWARemoteInterfaceDidObserveAuthenticationFailureNotification;
extern NSString * const kWASettingsDidRequestActionNotification;

extern NSString * const kWARemoteEndpointApplicationKeyPhone;
extern NSString * const kWARemoteEndpointApplicationKeyPad;
extern NSString * const kWARemoteEndpointApplicationKeyMac;

extern NSString * const kWACallbackActionDidFinishUserRegistration;
extern NSString * const kWACallbackActionSetAdvancedFeaturesEnabled;
extern NSString * const kWACallbackActionSetRemoteEndpointURL;

extern void WARegisterUserDefaults (void);
extern NSDictionary * WAPresetDefaults (void);

extern NSString * const kWACurrentGeneratedDeviceIdentifier;
BOOL WADeviceIdentifierReset (void);
NSString * WADeviceIdentifier (void);

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	#import "WADefines+iOS.h"
#else
	#import "WADefines+Mac.h"
#endif
