//
//  WAAppDelegate.m
//  wammer-OSX
//
//  Created by Evadne Wu on 9/15/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKitView.h>
#import "WAAppDelegate.h"

@implementation WAAppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	UIKitView *uiView = [[[UIKitView alloc] initWithFrame:[self.window.contentView bounds]] autorelease];
	uiView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
	[self.window.contentView addSubview:uiView];
	[uiView.UIWindow addSubview:((^{
		UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[button setTitle:@"Hello UIKit" forState:UIControlStateNormal];
		[button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[button setContentEdgeInsets:(UIEdgeInsets){ 6, 8, 8, 8 }];
		[button sizeToFit];
		return button;
	})())];
	
}

@end
