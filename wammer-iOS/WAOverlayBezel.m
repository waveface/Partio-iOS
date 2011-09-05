//
//  WAOverlayBezel.m
//  wammer-iOS
//
//  Created by Evadne Wu on 9/2/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAOverlayBezel.h"


@interface WAOverlayBezel ()

@property (nonatomic, readwrite, assign) WAOverlayBezelStyle *style;
@property (nonatomic, readwrite, retain) UIView *accessoryView;
@property (nonatomic, readwrite, retain) UILabel *captionLabel;
@property (nonatomic, readwrite, assign) CATransform3D deviceOrientationTransform;

- (void) handleDeviceOrientationDidChange:(NSNotification *)notification;

@end


@implementation WAOverlayBezel

@synthesize style, accessoryView, caption, captionLabel, deviceOrientationTransform;

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[accessoryView release];
	[caption release];
	[captionLabel release];
	[super dealloc];

}

+ (WAOverlayBezel *) bezelWithStyle:(WAOverlayBezelStyle)aStyle {

	return [[(WAOverlayBezel *)[self alloc] initWithStyle:aStyle] autorelease];

}

- (WAOverlayBezel *) initWithStyle:(WAOverlayBezelStyle)aStyle {

	self = [super initWithFrame:(CGRect){ CGPointZero, (CGSize){ 128, 128 }}];
	if (!self)
		return nil;
		
	self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65f];
	self.layer.cornerRadius = 8.0f;
	self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
	
	switch (aStyle) {
	
		case WAOverlayBezelSpinnerStyle: {
			
			UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
			[spinner startAnimating];
			
			self.accessoryView = spinner;;
		
			break;
		
		}
	
	}
	
	self.captionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	self.captionLabel.textColor = [UIColor whiteColor];
	self.captionLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	self.captionLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
	self.captionLabel.numberOfLines = 1;
	self.captionLabel.opaque = NO;
	self.captionLabel.backgroundColor = nil;
	
	self.deviceOrientationTransform = CATransform3DIdentity;
	[self handleDeviceOrientationDidChange:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
	
	return self;

}

- (id) initWithFrame:(CGRect)aFrame {

	self = [self initWithStyle:WAOverlayBezelDefaultStyle];
	if (!self)
		return nil;
	
	self.frame = aFrame;
	
	return self;

}

- (void) setCaption:(NSString *)newCaption {

	if (newCaption == caption)
		return;
	
	[self willChangeValueForKey:@"caption"];
	[caption release];
	caption = [newCaption copy];
	[self didChangeValueForKey:@"caption"];
	
	[self setNeedsLayout];

}

- (void) show {

	if (self.window)
		[NSException raise:NSInternalInconsistencyException format:@"%s shall only be called when the current alert view is not on screen.", __PRETTY_FUNCTION__];
	
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	[window addSubview:self];
	self.center = (CGPoint){
		CGRectGetMidX(window.bounds),
		CGRectGetMidY(window.bounds)
	};

}

- (void) dismiss {

	[self removeFromSuperview];

}

- (void) layoutSubviews {
	
	if (self.accessoryView) {
		[self addSubview:self.accessoryView];
		self.accessoryView.center = (CGPoint){
			CGRectGetMidX(self.bounds),
			CGRectGetMidY(self.bounds)
		};
	}
	
	self.captionLabel.text = self.caption;
	self.captionLabel.hidden = [[self.caption stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
	[self addSubview:self.captionLabel];
	[self.captionLabel sizeToFit];
	
	self.captionLabel.frame = CGRectIntegral((CGRect){
		(CGPoint){
			CGRectGetMidX(self.bounds) - (0.5f * CGRectGetWidth(self.captionLabel.frame)),
			CGRectGetMinY(self.bounds) + 10
		},
		(CGSize){
			MIN(MAX(0, (CGRectGetWidth(self.bounds) - 16)), CGRectGetWidth(self.captionLabel.frame)),
			CGRectGetHeight(self.captionLabel.frame)
		}
	});
	
	if (!CATransform3DEqualToTransform(self.layer.transform, self.deviceOrientationTransform))
		self.layer.transform = self.deviceOrientationTransform;

}

- (void) handleDeviceOrientationDidChange:(NSNotification *)notification {
	
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationPortrait: {
			self.deviceOrientationTransform = CATransform3DIdentity;
			break;
		}
		case UIInterfaceOrientationPortraitUpsideDown: {
			self.deviceOrientationTransform = CATransform3DMakeRotation(M_PI, 0.0, 0.0, 1.0);
			break;
		}
		case UIInterfaceOrientationLandscapeLeft: {
			self.deviceOrientationTransform = CATransform3DMakeRotation(-0.5 * M_PI, 0.0, 0.0, 1.0);
			break;
		}
		case UIInterfaceOrientationLandscapeRight: {
			self.deviceOrientationTransform = CATransform3DMakeRotation(0.5 * M_PI, 0.0, 0.0, 1.0);
			break;
		}
	};
	
	if ([[[notification userInfo] objectForKey:@"UIDeviceOrientationRotateAnimatedUserInfoKey"] isEqual:(id)kCFBooleanTrue]) {
	
		[UIView animateWithDuration:0.3f animations: ^ {
		
			[self layoutSubviews];
			
		}];
	
	} else {
	
		[self setNeedsLayout];
		
	}

}

@end
