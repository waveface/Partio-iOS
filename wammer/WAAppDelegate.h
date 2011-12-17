//
//  WAAppDelegate.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WAAppDelegate : NSObject

- (void) bootstrap;	//	Call for app initialization

- (BOOL) hasAuthenticationData;
- (BOOL) removeAuthenticationData;

- (void) updateCurrentCredentialsWithUserIdentifier:(NSString *)anIdentifier token:(NSString *)aToken primaryGroup:(NSString *)aGroupID;

@end


@interface WAAppDelegate (SubclassResponsibility)

//	Network activity indications.
//	Stackable.  Not thread safe.  Must invoke on main thread.

- (void) beginNetworkActivity;
- (void) endNetworkActivity;

@end