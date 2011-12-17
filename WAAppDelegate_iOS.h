//
//  WAAppDelegate_iOS.h
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAAppDelegate.h"

@interface WAAppDelegate_iOS : WAAppDelegate <UIApplicationDelegate, UIAlertViewDelegate>

@property (nonatomic, readwrite, retain) UIWindow *window;

- (BOOL) presentAuthenticationRequestRemovingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged;

- (BOOL) presentAuthenticationRequestWithReason:(NSString *)aReason allowingCancellation:(BOOL)allowsCancellation removingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged;

- (BOOL) presentAuthenticationRequestWithReason:(NSString *)aReason allowingCancellation:(BOOL)allowsCancellation removingPriorData:(BOOL)eraseAuthInfo clearingNavigationHierarchy:(BOOL)zapEverything onAuthSuccess:(void(^)(NSString *userIdentifier, NSString *userToken, NSString *primaryGroupIdentifier))successBlock runningOnboardingProcess:(BOOL)shouldRunOnboardingChecksIfUserUnchanged;
//  
//	Method will return immediately if an auth request view contorller has been presented
//  if erasesExistingAuthenticationInformation, removes stuff in the remote interface and nils currently stored user token as well
//  if zapEverything, removes all on-screen view controllers
//  if shouldRunOnboardingChecksIfUserUnchanged, runs onboarding checks such as station discovery if the newly authenticated user has a different identifier

//  - (BOOL) presentAuthenticationRequestRemovingPriorData:(BOOL)erasesExistingAuthenticationInformation DEPRECATED_ATTRIBUTE;

@end
