//
//  WANavigationState.m
//  wammer
//
//  Created by Evadne Wu on 4/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WANavigationState.h"


@interface WANavigationState (Private)

@property (nonatomic, readwrite) UIStatusBarStyle statusBarStyle;
@property (nonatomic, readwrite) BOOL statusBarHidden;

@property (nonatomic, readwrite) UIBarStyle navigationBarStyle;
@property (nonatomic, strong, readwrite) UIColor * navigationBarTintColor;
@property (nonatomic, readwrite) BOOL navigationBarHidden;

@property (nonatomic, readwrite) UIBarStyle toolBarStyle;
@property (nonatomic, strong, readwrite) UIColor * toolBarTintColor;
@property (nonatomic, readwrite) BOOL toolBarHidden;

@end


@implementation WANavigationState

@synthesize statusBarStyle, statusBarHidden, navigationBarStyle, navigationBarTintColor, navigationBarHidden, toolBarStyle, toolBarTintColor, toolBarHidden;

@end


@implementation UIViewController (WANavigationStateAdditions)

- (WANavigationState *) copyNavigationState {

	WANavigationState *state = [[WANavigationState alloc] init];
	UIApplication *app = [UIApplication sharedApplication];
	UINavigationController *navC = self.navigationController;
	
	state.statusBarStyle = app.statusBarStyle;
	state.statusBarHidden = app.statusBarHidden;
	
	state.navigationBarStyle = navC.navigationBar.barStyle;
	state.navigationBarTintColor = navC.navigationBar.tintColor;
	state.navigationBarHidden = navC.navigationBarHidden;
	
	state.toolBarStyle = navC.toolbar.barStyle;
	state.toolBarTintColor = navC.toolbar.tintColor;
	state.toolBarHidden = navC.toolbarHidden;
	
	return state;
	
}

- (void) configureWithNavigationState:(WANavigationState *)state {

	UIApplication *app = [UIApplication sharedApplication];
	UINavigationController *navC = self.navigationController;

}

@end
