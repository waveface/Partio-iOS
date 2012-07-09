//
//  WAAppDelegate_iOS.h
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAAppDelegate.h"
#import "FBConnect.h"

@interface WAAppDelegate_iOS : WAAppDelegate <UIApplicationDelegate, UIAlertViewDelegate, FBSessionDelegate>

@property (nonatomic, readwrite, retain) UIWindow *window;
@property (strong, nonatomic) Facebook *facebook;

@end
