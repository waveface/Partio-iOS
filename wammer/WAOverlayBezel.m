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
		case WACloudBezelStyle: {
			self.image = [UIImage imageNamed:@"WAOverlayBezel-Cloud"];
			break;
		}
		case WAConnectionBezelStyle: {
			self.image = [UIImage imageNamed:@"WAOverlayBezel-Connection"];
			break;
		}
		case WAErrorBezelStyle: {
			self.image = [UIImage imageNamed:@"WAOverlayBezel-Error"];
			break;
		}
		case WARestrictedBezelStyle: {
			self.image = [UIImage imageNamed:@"WAOverlayBezel-Restricted"];
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
	self.captionLabel.textAlignment = UITextAlignmentCenter;
	
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

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	self.center = (CGPoint){
		roundf(CGRectGetMidX(self.window.irInterfaceBounds)),
		roundf(CGRectGetMidY(self.window.irInterfaceBounds))
	};

}

- (void) showWithAnimation:(WAOverlayBezelAnimation)anAnimation {

	if (self.window)
		[NSException raise:NSInternalInconsistencyException format:@"%s shall only be called when the current alert view is not on screen.", __PRETTY_FUNCTION__];
	
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	NSParameterAssert(window);
	
	[window addSubview:self];
	
	[window addObserver:self forKeyPath:@"irInterfaceBounds" options:NSKeyValueObservingOptionNew context:nil];
	[self observeValueForKeyPath:@"irInterfaceBounds" ofObject:nil change:nil context:nil];

}

- (void) dismissWithAnimation:(WAOverlayBezelAnimation)anAnimation {

	[self.window removeObserver:self forKeyPath:@"irInterfaceBounds"];

	void (^remove)() = ^ {
		[self removeFromSuperview];
	};
	
	if (anAnimation == WAOverlayBezelAnimationNone) {
		remove();
		return;
	}

	NSTimeInterval duration = 0.5f;
	
	NSMutableArray *animations = [NSMutableArray array];
	
	id (^configureAnimation)(CAAnimation *) = ^ (CAAnimation *anAnimation){
		anAnimation.duration = duration;
		anAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		anAnimation.fillMode = kCAFillModeForwards;
		anAnimation.removedOnCompletion = NO;
		return anAnimation;
	};
	
	if (anAnimation & WAOverlayBezelAnimationFade) {
		CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeOutAnimation = configureAnimation(fadeOutAnimation);
		fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1.0f];
		fadeOutAnimation.toValue = [NSNumber numberWithFloat:0.0f];
		[animations addObject:fadeOutAnimation];	
	}
	
	if (anAnimation & WAOverlayBezelAnimationSlide) {
		CABasicAnimation *slideOutAnimation = [CABasicAnimation animationWithKeyPath:@"transform.y"];
		slideOutAnimation = configureAnimation(slideOutAnimation);
		slideOutAnimation.fromValue = [NSNumber numberWithFloat:0.0f];	
		slideOutAnimation.toValue = [NSNumber numberWithFloat:-32.0f];
		[animations addObject:slideOutAnimation];
	}

	if (anAnimation & WAOverlayBezelAnimationZoom) {
		CABasicAnimation *zoomInAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
		zoomInAnimation = configureAnimation(zoomInAnimation);
		zoomInAnimation.fromValue = [NSNumber numberWithFloat:1.0f];	
		zoomInAnimation.toValue = [NSNumber numberWithFloat:0.25f];
		[animations addObject:zoomInAnimation];
	}
	
	if (!animations) {
		remove();
		return;
	}
	
	CAAnimationGroup *orderOutAnimation = [CAAnimationGroup animation];
	orderOutAnimation.animations = animations;
	orderOutAnimation.duration = duration;
	orderOutAnimation.removedOnCompletion = YES;
	orderOutAnimation.fillMode = kCAFillModeForwards;
	orderOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	[CATransaction begin];
	
	[self.layer addAnimation:orderOutAnimation forKey:kCATransition];
	
	for (CABasicAnimation *anAnimation in orderOutAnimation.animations)
		[self.layer setValue:anAnimation.toValue forKey:anAnimation.keyPath];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), remove);
	
	[CATransaction commit];

}

- (void) layoutSubviews {

	[CATransaction begin];
	[CATransaction setDisableActions:YES];

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
		self.accessoryView.frame = CGRectIntegral(self.accessoryView.frame);
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

	[CATransaction commit];

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
