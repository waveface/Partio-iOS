//
//  WANavigationState.h
//  wammer
//
//  Created by Evadne Wu on 4/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface WANavigationState : NSObject

@property (nonatomic, readonly) UIStatusBarStyle statusBarStyle;
@property (nonatomic, readonly) BOOL statusBarHidden;

@property (nonatomic, readonly) UIBarStyle navigationBarStyle;
@property (nonatomic, strong, readonly) UIColor * navigationBarTintColor;
@property (nonatomic, readonly) BOOL navigationBarHidden;

@property (nonatomic, readonly) UIBarStyle toolBarStyle;
@property (nonatomic, strong, readonly) UIColor * toolBarTintColor;
@property (nonatomic, readonly) BOOL toolBarHidden;

@end


@interface UIViewController (WANavigationStateAdditions)

- (WANavigationState *) copyNavigationState;
- (void) configureWithNavigationState:(WANavigationState *)state;

@end
