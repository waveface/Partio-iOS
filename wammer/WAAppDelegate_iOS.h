//
//  WAAppDelegate_iOS.h
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAAppDelegate.h"

@class WACacheManager, WASyncManager, WAFetchManager, WASlidingMenuViewController;
@interface WAAppDelegate_iOS : WAAppDelegate <UIApplicationDelegate, UIAlertViewDelegate>

@property (nonatomic, readwrite, retain) UIWindow *window;
@property (nonatomic, readonly, strong) WACacheManager *cacheManager;
@property (nonatomic, readonly, strong) WASyncManager *syncManager;
@property (nonatomic, readonly, strong) WAFetchManager *fetchManager;
@property (nonatomic, readonly, strong) WASlidingMenuViewController *slidingMenu;

- (void) recreateViewHierarchy;
+ (void) backgroundLoginWithFacebookIDWithCompleteHandler:(void(^)(NSError *error))completionHandler;

@end
