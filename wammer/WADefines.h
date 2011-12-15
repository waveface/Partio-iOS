//
//  WADefines.h
//  wammer
//
//  Created by Evadne Wu on 10/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IRBarButtonItem, IRBorder;

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

extern NSString * const kWACompositionSessionRequestedNotification;
extern NSString * const kWAApplicationDidReceiveRemoteURLNotification;
extern NSString * const kWARemoteInterfaceReachableHostsDidChangeNotification;

extern NSString * const kWARemoteEndpointApplicationKeyPhone;
extern NSString * const kWARemoteEndpointApplicationKeyPad;

extern void WARegisterUserDefaults (void);
extern NSDictionary * WAPresetDefaults (void);

extern IRBarButtonItem * WAStandardBarButtonItem (NSString *labelText, void(^block)(void));
extern IRBarButtonItem * WABackBarButtonItem (NSString *labelText, void(^block)(void));

extern UIButton * WAButtonForImage (UIImage *anImage);
extern UIButton * WAToolbarButtonForImage (UIImage *anImage);
extern UIImage * WABarButtonImageFromImageNamed (NSString *anImageName);

extern NSString * const kWACurrentGeneratedDeviceIdentifier;
BOOL WADeviceIdentifierReset (void);
NSString * WADeviceIdentifier (void);
