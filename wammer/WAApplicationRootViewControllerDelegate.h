//
//  WAApplicationRootViewControllerDelegate.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/30/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol WAApplicationRootViewController;
@protocol WAApplicationRootViewControllerDelegate <NSObject>
- (void) applicationRootViewControllerDidRequestReauthentication:(id<WAApplicationRootViewController>)controller;
- (void) applicationRootViewControllerDidRequestChangeAPIURL:(id<WAApplicationRootViewController>)controller;
@end

@protocol WAApplicationRootViewController
@property (nonatomic, readwrite, assign) id <WAApplicationRootViewControllerDelegate> delegate;
@end
