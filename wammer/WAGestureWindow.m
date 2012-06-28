//
//  WAGestureWindow.m
//  wammer
//
//  Created by Evadne Wu on 1/11/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAGestureWindow.h"


@interface WAGestureWindow () <UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, retain) UITapGestureRecognizer *tapGestureRecognizer;

- (void) handleTapGesture:(UITapGestureRecognizer *)aTGR;

- (void) handleAppWillChangeStatusBarOrientation:(NSNotification *)note;
- (void) handleAppDidChangeStatusBarOrientation:(NSNotification *)note;

@end


@implementation WAGestureWindow
@synthesize tapGestureRecognizer, onTap, onGestureRecognizeShouldReceiveTouch, onGestureRecognizeShouldRecognizeSimultaneouslyWithGestureRecognizer;

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
	tapGestureRecognizer.delegate = self;
	
	[self addGestureRecognizer:tapGestureRecognizer];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppWillChangeStatusBarOrientation:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppDidChangeStatusBarOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

	return self;

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	if (self.onGestureRecognizeShouldReceiveTouch) {
		BOOL returnValue = self.onGestureRecognizeShouldReceiveTouch(gestureRecognizer, touch);
		return returnValue;
	}
	
	return NO;

}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

	if (self.onGestureRecognizeShouldRecognizeSimultaneouslyWithGestureRecognizer)
		return self.onGestureRecognizeShouldRecognizeSimultaneouslyWithGestureRecognizer(gestureRecognizer, otherGestureRecognizer);

	return YES;

}

- (void) handleTapGesture:(UITapGestureRecognizer *)aTGR {

	if (onTap)
		onTap();

}

- (void) setRootViewController:(UIViewController *)rootViewController {

	[super setRootViewController:rootViewController];

	[self tile];

}

- (void) handleAppWillChangeStatusBarOrientation:(NSNotification *)note {

//	[self tile];
	
}

- (void) handleAppDidChangeStatusBarOrientation:(NSNotification *)note {

	[self tile];
	
}

- (void) tile {

	//	TBD remove
	return;

	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

	switch (orientation) {

		case UIInterfaceOrientationLandscapeLeft: {
			self.transform = CGAffineTransformMakeRotation(1.5f * M_PI);
			break;
		}
		
		case UIInterfaceOrientationLandscapeRight: {
			self.transform = CGAffineTransformMakeRotation(0.5f * M_PI);
			break;
		}

		case UIInterfaceOrientationPortrait: {
			self.transform = CGAffineTransformMakeRotation(0.0f * M_PI);
			break;
		}
		
		case UIInterfaceOrientationPortraitUpsideDown: {
			self.transform = CGAffineTransformMakeRotation(1.0f * M_PI);
			break;
		}

	}
	
	CGRect newBounds = [UIScreen mainScreen].bounds;
	newBounds.origin = CGPointZero;
	
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		newBounds.size = (CGSize){ newBounds.size.height, newBounds.size.width };
	}
	
	self.bounds = newBounds;
	self.rootViewController.view.bounds = self.bounds;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

@end
