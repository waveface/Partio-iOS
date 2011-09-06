//
//  WAOverlayBezel.m
//  wammer-iOS
//
//  Created by Evadne Wu on 9/2/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAOverlayBezel.h"


@interface WAOverlayBezel ()

@property (nonatomic, readwrite, retain) UIImage *image;
@property (nonatomic, readwrite, assign) WAOverlayBezelStyle *style;
@property (nonatomic, readwrite, retain) UIView *accessoryView;
@property (nonatomic, readwrite, retain) UILabel *captionLabel;
@property (nonatomic, readwrite, assign) CATransform3D deviceOrientationTransform;

- (void) handleDeviceOrientationDidChange:(NSNotification *)notification;

@end


@implementation WAOverlayBezel

@synthesize image, style, accessoryView, caption, captionLabel, deviceOrientationTransform;

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[image release];
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
	
		case WAActivityIndicatorBezelStyle: {
			
			UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
			[spinner startAnimating];
			
			self.accessoryView = spinner;;
		
			break;
		
		}
		
		case WACheckmarkBezelStyle: {
			self.image = [UIImage imageNamed:@"WAOverlayBezel-Checkmark"];
			break;
		}
		case WAErrorBezelStyle: {
			self.image = [UIImage imageNamed:@"WAOverlayBezel-Error"];
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

	self = [self initWithStyle:WADefaultBezelStyle];
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

	[self showWithAnimation:WAOverlayBezelAnimationDefault];

}

- (void) dismiss {

	[self dismissWithAnimation:WAOverlayBezelAnimationDefault];

}

- (void) showWithAnimation:(WAOverlayBezelAnimation)anAnimation {

	if (self.window)
		[NSException raise:NSInternalInconsistencyException format:@"%s shall only be called when the current alert view is not on screen.", __PRETTY_FUNCTION__];
	
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	[window addSubview:self];
	self.center = (CGPoint){
		CGRectGetMidX(window.bounds),
		CGRectGetMidY(window.bounds)
	};

}

- (void) dismissWithAnimation:(WAOverlayBezelAnimation)anAnimation {

	NSTimeInterval duration = 0.3f;
	
	[CATransaction begin];
	
	NSMutableArray *animations = [NSMutableArray array];
	
	CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeOutAnimation.toValue = [NSNumber numberWithFloat:0.0f];
	[animations addObject:fadeOutAnimation];
	
	CAAnimationGroup *orderOutAnimation = [CAAnimationGroup animation];
	orderOutAnimation.animations = animations;
	orderOutAnimation.duration = duration;
	orderOutAnimation.removedOnCompletion = YES;
	orderOutAnimation.fillMode = kCAFillModeForwards;
	orderOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	[self.layer addAnimation:orderOutAnimation forKey:kCAOnOrderOut];
	
	[CATransaction setCompletionBlock: ^ {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
			[self removeFromSuperview];
		});
	}];
	
	[CATransaction commit];

}

- (void) layoutSubviews {

	if (self.image) {
		
		if (!self.accessoryView)
			self.accessoryView = [[[UIImageView alloc] initWithImage:self.image] autorelease];
		
		UIImageView *currentImageView = [self.accessoryView isKindOfClass:[UIImageView class]] ? (UIImageView *)self.accessoryView : nil;
		
		if (!currentImageView)
			NSLog(@"Warning: %@ has an image, but its accessory view is set to something other than a default image view provided by itself.  The image will not show, or there will be inconsistent behavior.", self);
		
		currentImageView.image = self.image;
		[currentImageView sizeToFit];
		
	}
	
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
