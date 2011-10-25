//
//  WARefreshActionView.m
//  wammer
//
//  Created by Evadne Wu on 10/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARefreshActionView.h"
#import "WADefines.h"
#import "WARemoteInterface.h"

@interface WARefreshActionView ()

- (void) updateStateAnimated:(BOOL)animate;

@property (nonatomic, readwrite, retain) WARemoteInterface *interface;
@property (nonatomic, readwrite, retain) UIButton *actionButton;
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *activityIndicatorView;

@end


@implementation WARefreshActionView
@synthesize interface, actionButton, activityIndicatorView;

- (id) initWithFrame:(CGRect)frame {

	return [self initWithRemoteInterface:nil];

}

- (id) initWithRemoteInterface:(WARemoteInterface *)anInterface {

	self = [super initWithFrame:(CGRect){ 0, 0, 24, 24 }];
	if (!self)
		return nil;
	
	self.interface = anInterface;
	[self addSubview:self.actionButton];
	[self addSubview:self.activityIndicatorView];

	//	self.actionButton.center = (CGPoint){ 12, 12 };
	self.activityIndicatorView.center = (CGPoint){ 12, 12 };
	
	[self.interface addObserver:self forKeyPath:@"isPerformingAutomaticRemoteUpdates" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
	
	return self;

}

- (void) dealloc {

	[interface removeObserver:self forKeyPath:@"isPerformingAutomaticRemoteUpdates"];

	[interface release];
	[actionButton release];
	[activityIndicatorView release];
	
	[super dealloc];

}

- (UIButton *) actionButton {

	if (actionButton)
		return actionButton;
	
	actionButton = [WAButtonForImage(WABarButtonImageFromImageNamed(@"WARefreshGlyph")) retain];

	actionButton.contentEdgeInsets = UIEdgeInsetsZero;
	actionButton.imageEdgeInsets = (UIEdgeInsets){ 0, 0, 0, 2 };

	[actionButton addTarget:self action:@selector(handleActionButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	
	return actionButton;

}

- (UIActivityIndicatorView *) activityIndicatorView {

	if (activityIndicatorView)
		return activityIndicatorView;
	
	activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	
	activityIndicatorView.hidesWhenStopped = NO;
	
	[activityIndicatorView startAnimating];
	
	return activityIndicatorView;

}

- (void) handleActionButtonTap:(UIButton *)sender {

	[self.interface performAutomaticRemoteUpdatesNow];
	[self updateStateAnimated:YES];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	[self updateStateAnimated:YES];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	[self updateStateAnimated:NO];

}

- (void) updateStateAnimated:(BOOL)animate {

	void (^animations)() = ^ {

		if (self.interface.performingAutomaticRemoteUpdates) {
		
			self.actionButton.alpha = 0;
			self.actionButton.transform = CGAffineTransformConcat(
				CGAffineTransformMakeRotation(30 * (2 * M_PI / 360.0f)),
				CGAffineTransformMakeScale(0.1, 0.1));
			self.activityIndicatorView.alpha = 1;
		
		} else {

			self.actionButton.alpha = 1;
			self.actionButton.transform = CGAffineTransformIdentity;
			self.activityIndicatorView.alpha = 0;
			
		}
	
	};
	
	if (animate) {
	
		[UIView animateWithDuration:0.25 animations:animations];
	
	} else {
	
		animations();
	
	}

}

@end
