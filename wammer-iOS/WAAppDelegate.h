//
//  WAAppDelegate.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, readwrite, retain) UIWindow *window;

//	Network activity indications.
//	Stackable.  Not thread safe.  Must invoke on main thread.

- (void) beginNetworkActivity;
- (void) endNetworkActivity;

- (BOOL) hasAuthenticationData;
- (void) presentAuthenticationRequestRemovingPriorData:(BOOL)erasesExistingAuthenticationInformation;

@end
