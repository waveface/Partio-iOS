//
//  WAAppDelegate.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	#import <UIKit/UIKit.h>
	#define WAAppDelegateRootClass UIResponder
#else
	#import <Cocoa/Cocoa.h>
	#define WAAppDelegateRootClass NSResponder
#endif

@interface WAAppDelegate : WAAppDelegateRootClass

- (void) bootstrap;	//	Call for app initialization

- (BOOL) hasAuthenticationData;
- (BOOL) removeAuthenticationData;

- (void) updateCurrentCredentialsWithUserIdentifier:(NSString *)anIdentifier token:(NSString *)aToken primaryGroup:(NSString *)aGroupID;
- (void) bootstrapPersistentStoreWithUserIdentifier:(NSString *)identifier;

@end


@interface WAAppDelegate (SubclassResponsibility)

//	Network activity indications.
//	Stackable.  Not thread safe.  Must invoke on main thread.

- (void) beginNetworkActivity;
- (void) endNetworkActivity;

@end