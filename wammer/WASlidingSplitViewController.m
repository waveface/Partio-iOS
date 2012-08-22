//
//  WASlidingSplitViewController.m
//  wammer
//
//  Created by Evadne Wu on 7/3/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <objc/runtime.h>
#import "WASlidingSplitViewController.h"


@interface WASlidingSplitViewController ()

@property (nonatomic, readonly, strong) UIView *overlayView;
- (void) updateOverlayView;

@end


@implementation WASlidingSplitViewController
@synthesize overlayView = _overlayView;

- (id) initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {

	self = [super initWithNibName:nibName bundle:nibBundle];
	if (!self)
		return nil;
	
	[self addObserver:self forKeyPath:@"detailViewController.view.frame" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
	
	return self;

}

- (void) dealloc {
	
	[self removeObserver:self forKeyPath:@"detailViewController.view.frame"];

}

- (CGRect) rectForDetailView {

	if (self.showingMasterViewController)
		return CGRectOffset(self.view.bounds, 0.0f, CGRectGetHeight(self.view.bounds));
	
	return self.view.bounds;

}

- (CGPoint) detailViewTranslationForGestureTranslation:(CGPoint)translation {

	return (CGPoint){ 0.0f, MAX(0, translation.y) };

}

- (BOOL) shouldShowMasterViewControllerWithGestureTranslation:(CGPoint)translation {

	if (!self.showingMasterViewController && translation.y > 160.0f)
		return YES;
		
	if (self.showingMasterViewController && translation.y < 0)
		return NO;
	
	return self.showingMasterViewController;

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {

	return YES;

}

- (void) layoutViews {

	[super layoutViews];
	
	[self.view insertSubview:self.overlayView aboveSubview:self.masterViewController.view];
	self.overlayView.frame = self.overlayView.superview.bounds;
	
	[self updateOverlayView];

}

- (UIView *) overlayView {

	if (!_overlayView) {
	
		_overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
		_overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		_overlayView.userInteractionEnabled = NO;
		_overlayView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.85f];
		_overlayView.alpha = 0.0f;
	
	}
	
	return _overlayView;

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	Method rootMethod = class_getInstanceMethod([NSObject class], _cmd);
	Method superMethod = class_getInstanceMethod([self superclass], _cmd);
	Method ownMethod = class_getInstanceMethod([self class], _cmd);
	
	if (superMethod != rootMethod)
	if (superMethod != ownMethod)
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	if (object == self)
	if ([keyPath isEqualToString:@"detailViewController.view.frame"])
		[self updateOverlayView];
	
}

- (void) updateOverlayView {

	CGRect masterRect = [self rectForMasterView];
	CGRect detailRect = self.detailViewController.view.frame;
	
	CGRect overlap = CGRectIntersection(detailRect, masterRect);
	
	if (CGRectEqualToRect(CGRectNull, overlap))
		_overlayView.alpha = 0.0f;
	else
		_overlayView.alpha = (CGRectGetWidth(overlap) * CGRectGetHeight(overlap)) / (CGRectGetWidth(masterRect) * CGRectGetHeight(masterRect));

}

@end
