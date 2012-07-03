//
//  WASlidingSplitViewController.m
//  wammer
//
//  Created by Evadne Wu on 7/3/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASlidingSplitViewController.h"

@implementation WASlidingSplitViewController

- (CGRect) rectForDetailView {

	if (self.showingMasterViewController)
		return CGRectOffset(self.view.bounds, 0.0f, CGRectGetHeight(self.view.bounds));
	
	return self.view.bounds;

}

- (CGPoint) detailViewTranslationForGestureTranslation:(CGPoint)translation {

	return (CGPoint){ 0.0f, translation.y };

}

- (BOOL) shouldShowMasterViewControllerWithGestureTranslation:(CGPoint)translation {

	if (!self.showingMasterViewController && translation.y > 0)
		return YES;
		
	if (self.showingMasterViewController && translation.y < 0)
		return NO;
	
	return self.showingMasterViewController;

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {

	return YES;

}

@end
