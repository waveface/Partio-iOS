//
//  WAGalleryImageView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/5/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAGalleryImageView.h"
#import "WAImageView.h"

#import "CGGeometry+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"

#import "WAGalleryImageScrollView.h"


@interface WAGalleryImageView () <UIScrollViewDelegate, WAImageViewDelegate>
@property (nonatomic, readwrite, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, readwrite, retain) UIScrollView *scrollView;
@property (nonatomic, readwrite, retain) WAImageView *imageView;

@end


@implementation WAGalleryImageView

@synthesize activityIndicator, imageView, scrollView;
@synthesize delegate;

+ (WAGalleryImageView *) viewForImage:(UIImage *)image {

	WAGalleryImageView *returnedView = [[self alloc] init];
	returnedView.image = image;
	
	return returnedView;

}

- (void) waInit {
	
	[self addSubview:self.activityIndicator];
	[self addSubview:self.scrollView];
	
	#if 0
	
		self.clipsToBounds = NO;
		self.scrollView.clipsToBounds = NO;
		self.imageView.clipsToBounds = NO;
		
		self.scrollView.layer.borderColor = [UIColor blueColor].CGColor;
		self.scrollView.layer.borderWidth = 2.0f;
		
		self.imageView.layer.borderColor = [UIColor greenColor].CGColor;
		self.imageView.layer.borderWidth = 1.0f;
	
	#endif
	
	[self setNeedsLayout];
	
	self.exclusiveTouch = YES;
	
}

- (UIActivityIndicatorView *) activityIndicator {

	if (!activityIndicator) {
	
		activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
		activityIndicator.hidesWhenStopped = NO;
		activityIndicator.center = (CGPoint){ CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds) };
		
		[activityIndicator startAnimating];
	
	}
	
	return activityIndicator;

}

- (UIScrollView *) scrollView {

	if (!scrollView) {
	
		scrollView = [[WAGalleryImageScrollView alloc] initWithFrame:self.bounds];
		scrollView.minimumZoomScale = 1.0f;
		scrollView.maximumZoomScale = 4.0f;
		scrollView.showsHorizontalScrollIndicator = NO;
		scrollView.showsVerticalScrollIndicator = NO;
		scrollView.delegate = self;
		scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		
		[scrollView addSubview:self.imageView];
	
	}
	
	return scrollView;

}

- (WAImageView *) imageView {

	if (!imageView) {
	
		imageView = [[WAImageView alloc] initWithFrame:self.scrollView.bounds];
		imageView.center = CGPointZero;
		imageView.autoresizingMask = UIViewAutoresizingNone;
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.delegate = self;
	
	}
	
	return imageView;

}

- (void) imageViewDidUpdate:(WAImageView *)anImageView {

	//	?

}

- (void) setImage:(UIImage *)newImage animated:(BOOL)animate synchronized:(BOOL)sync {

	NSTimeInterval duration = (animate ? 0.3f : 0.0f);
	NSTimeInterval delay = 0.0f;
	UIViewAnimationOptions options = UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState;

	self.activityIndicator.hidden = !!newImage;
	
	[UIView animateWithDuration:duration delay:delay options:options animations:^{
	
		[self.imageView setImage:newImage withOptions:(sync ? WAImageViewForceSynchronousOption : WAImageViewForceAsynchronousOption)];
				
	} completion:nil];

}

+ (NSSet *) keyPathsForValuesAffectingImage {

	return [NSSet setWithObject:@"imageView.image"];

}

- (UIImage *) image {

	return self.imageView.image;

}

- (void) setImage:(UIImage *)newImage {

	[self setImage:newImage animated:NO synchronized:NO];

}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)aScrollView {

	return self.imageView;

}

- (void) setFrame:(CGRect)newFrame {

	BOOL frameChanged = !CGRectEqualToRect(self.frame, newFrame);

	[super setFrame:newFrame];
	
	if (frameChanged) {
		[self.scrollView setZoomScale:1.0f animated:NO];
		[self layoutSubviews];
	}

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	UIScrollView *sv = self.scrollView;
	UIImageView *iv = self.imageView;
	CGFloat zs = sv.zoomScale;
	
	if (!iv.image)
		return;
	
	if (zs == 1) {
		
		iv.frame = IRGravitize(sv.bounds, iv.image.size, kCAGravityResizeAspect);
		sv.contentSize = sv.bounds.size;
	
	}
	
}

- (void) scrollViewDidScroll:(UIScrollView *)sv {

	if (sv.panGestureRecognizer.state == UIGestureRecognizerStateChanged)
		[self.delegate galleryImageViewDidReceiveUserInteraction:self];

}

- (void) scrollViewDidZoom:(UIScrollView *)sv {

	if (sv.pinchGestureRecognizer.state == UIGestureRecognizerStateChanged)
		[self.delegate galleryImageViewDidReceiveUserInteraction:self];

	UIImageView *iv = self.imageView;
	CGFloat zs = sv.zoomScale;
	
	if (!iv.image)
		return;
	
	if (zs == 1) {
		
		iv.frame = IRGravitize(sv.bounds, iv.image.size, kCAGravityResizeAspect);
		sv.contentSize = sv.bounds.size;
	
	}

}

- (void) reset {

	[self.scrollView setZoomScale:1 animated:YES];
	
}

- (id) initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (!self)
		return nil;
		
	[self waInit];
	
	return self;

}

- (id) initWithCoder:(NSCoder *)aDecoder {
	
	self = [super initWithCoder:aDecoder];
	if (!self)
		return nil;
		
	[self waInit];
	
	return self;

}

- (void) handleDoubleTap:(UITapGestureRecognizer *)aRecognizer {

	[self.delegate galleryImageViewDidReceiveUserInteraction:self];

	//	TBD: use me
	//	CGPoint locationInImageView = [aRecognizer locationInView:self.imageView];
	
	UIScrollView *sv = self.scrollView;
	CGFloat zsMin = sv.minimumZoomScale, zsMax = sv.maximumZoomScale, zs = sv.zoomScale;
	
	if (zs == 1) {
	
		NSTimeInterval duration = 0.3f;
		NSTimeInterval delay = 0.0f;
		UIViewAnimationOptions options = UIViewAnimationCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState;
	
		[UIView animateWithDuration:duration delay:delay options:options animations:^{
			
			[sv setZoomScale:zsMax animated:NO];
			
			//	TBD: Make sure point locationInImageView in image view is actually visible with best efforts

		} completion:nil];
	
	} else if (zs > 1) {
	
		[sv setZoomScale:zsMin animated:YES];
	
	}

}

@end
