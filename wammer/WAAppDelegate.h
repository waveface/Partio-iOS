//
//  WAAppDelegate.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIWindow+IRAdditions.h"

@interface WAAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (nonatomic, readwrite, retain) UIWindow *window;

//	Network activity indications.
//	Stackable.  Not thread safe.  Must invoke on main thread.

- (void) beginNetworkActivity;
- (void) endNetworkActivity;

- (BOOL) hasAuthenticationData;

- (BOOL) presentAuthenticationRequestRemovingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged;

- (BOOL) presentAuthenticationRequestWithReason:(NSString *)aReason allowingCancellation:(BOOL)allowsCancellation removingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged;
//  
//	Method will return immediately if an auth request view contorller has been presented
//  if erasesExistingAuthenticationInformation, removes stuff in the remote interface and nils currently stored user token as well
//  if zapEverything, removes all on-screen view controllers
//  if shouldRunOnboardingChecksIfUserUnchanged, runs onboarding checks such as station discovery if the newly authenticated user has a different identifier

//  - (BOOL) presentAuthenticationRequestRemovingPriorData:(BOOL)erasesExistingAuthenticationInformation DEPRECATED_ATTRIBUTE;

@end
