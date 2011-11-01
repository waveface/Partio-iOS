//
//  WANavigationController.h
//  wammer
//
//  Created by Evadne Wu on 10/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WANavigationController : UINavigationController

@property (nonatomic, readwrite, copy) void (^onViewDidLoad)(WANavigationController *self);
@property (nonatomic, readwrite, copy) void (^willPushViewControllerAnimated)(WANavigationController *self, UIViewController *pushedVC, BOOL animated);
@property (nonatomic, readwrite, copy) void (^didPushViewControllerAnimated)(WANavigationController *self, UIViewController *pushedVC, BOOL animated);
@property (nonatomic, readwrite, copy) void (^onDismissModalViewControllerAnimated)(WANavigationController *self, BOOL animated);

@property (nonatomic, readwrite, assign) BOOL disablesAutomaticKeyboardDismissal;

@end
