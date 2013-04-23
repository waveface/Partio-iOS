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

extern BOOL WAApplicationHasDebuggerAttached (void);

extern NSString * const kWARemoteEndpointURL;
extern NSString * const kWARemoteEndpointVersion;
extern NSString * const kWARemoteEndpointCurrentVersion;
extern NSString * const kWARemoteEndpointWebURL;
extern NSString * const kWALastAuthenticatedUserTokenKeychainItem;
extern NSString * const kWALastAuthenticatedUserPrimaryGroupIdentifier;
extern NSString * const kWALastAuthenticatedUserIdentifier;
extern NSString * const kWAUserRegistrationUsesWebVersion;
extern NSString * const kWAUserRegistrationEndpointURL;
extern NSString * const kWAUserFacebookAuthenticationEndpointURL;
extern NSString * const kWAUserRequiresReauthentication;
extern NSString * const kWAUserPasswordResetEndpointURL;
extern NSString * const kWAAlwaysAllowExpensiveRemoteOperations;
extern NSString * const kWAAlwaysDenyExpensiveRemoteOperations;
extern NSString * const kWADebugAutologinUserIdentifier;
extern NSString * const kWADebugAutologinUserPassword;

extern NSString * const kWADebugLastScanSyncBezelsVisible;
extern NSString * const kWADebugPersistentStoreName;

extern NSString * const kWACompositionSessionRequestedNotification;
extern NSString * const kWAApplicationDidReceiveRemoteURLNotification;
extern NSString * const kWARemoteInterfaceDidObserveAuthenticationFailureNotification;
extern NSString * const kWASettingsDidRequestActionNotification;
extern NSString * const kWACoreDataReinitialization;

extern NSString * const kWAFacebookDidLoginNotification;
extern NSString * const kWAFacebookAppID;
extern NSString * const kWAFacebookTokenKey;
extern NSString * const kWAFacebookExpirationDateKey;

extern NSString * const kWATwitterConsumerKey;
extern NSString * const kWATwitterConsumerSecret;

extern NSString * const kWACrashlyticsAPIKey;

extern NSString * const kWAGoogleAnalyticsAccountID;
extern NSInteger  const kWAGoogleAnalyticsDispatchInterval;

extern NSString * const kWARemoteEndpointApplicationKeyPhone;
extern NSString * const kWARemoteEndpointApplicationKeyPad;
extern NSString * const kWARemoteEndpointApplicationKeyMac;

extern NSString * const kWACallbackActionDidFinishUserRegistration;
extern NSString * const kWACallbackActionSetAdvancedFeaturesEnabled;
extern NSString * const kWACallbackActionSetRemoteEndpointURL;
extern NSString * const kWACallbackActionSetUserRegistrationEndpointURL;
extern NSString * const kWACallbackActionSetUserPasswordResetEndpointURL;

extern NSString * const kWAPhotoImportEnabled;
extern NSString * const kWAFirstUseVisited;
extern NSString * const kWAUseCellularEnabled;
extern NSString * const kWABackupFilesToCloudEnabled;

extern NSString * const kWABusinessPlan;

typedef NS_ENUM(NSInteger, WABusinessPlanType) {
  WABusinessPlanFree,
  WABusinessPlanPremium,
  WABusinessPlanUltimate
};

typedef NS_ENUM(NSInteger, WAThumbnailType) {
  WAThumbnailTypeExtraSmall,
  WAThumbnailTypeSmall,
  WAThumbnailTypeMedium,
  WAThumbnailTypeLarge
};

extern NSString * const kWASNSFacebookConnectEnabled;
extern NSString * const kWASNSGoogleConnectEnabled;
extern NSString * const kWASNSTwitterConnectEnabled;
extern NSString * const kWASNSFoursquareConnectEnabled;

extern NSString * const kWAFirstArticleFetched;
extern NSString * const kWAAllCollectionsFetchOnce;

extern NSString * const WAFeedbackRecipient;
extern NSString * const WAStreamFeaturesURL;

extern void WARegisterUserDefaults (void);
extern NSDictionary * WAPresetDefaults (void);

extern NSString * const kWACurrentGeneratedDeviceIdentifier;
BOOL WADeviceIdentifierReset (void);
extern NSString * WADeviceIdentifier (void);
extern NSString * WADeviceName (void);

extern NSString * const kWAAppEventNotification;	//	Notification Center key
extern NSString * const kWAAppEventTitle;	//	The eventTitle
extern void WAPostAppEvent (NSString *eventTitle, NSDictionary *userInfo);

extern NSString * const kWADucklingsEnabled;
extern BOOL WADucklingsEnabled (void);

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	#import "WADefines+iOS.h"
#else
	#import "WADefines+Mac.h"
#endif
