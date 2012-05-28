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

@property (nonatomic, readwrite, assign) BOOL needsContentAdjustmentOnLayout;
@property (nonatomic, readwrite, assign) BOOL needsInsetAdjustmentOnLayout;
@property (nonatomic, readwrite, assign) BOOL needsOffsetAdjustmentOnLayout;
@property (nonatomic, readwrite, assign) BOOL revertsOnZoomEnd;

@end


@implementation WAGalleryImageView

@synthesize activityIndicator, imageView, scrollView;
@synthesize needsContentAdjustmentOnLayout, needsInsetAdjustmentOnLayout, needsOffsetAdjustmentOnLayout, revertsOnZoomEnd;
@synthesize delegate;

+ (WAGalleryImageView *) viewForImage:(UIImage *)image {

	WAGalleryImageView *returnedView = [[self alloc] init];
	returnedView.image = image;
	
	return returnedView;

}

- (void) waInit {
	
	self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
	self.activityIndicator.hidesWhenStopped = NO;
	self.activityIndicator.center = (CGPoint){
		CGRectGetMidX(self.bounds),
		CGRectGetMidY(self.bounds)
	};
	[self.activityIndicator startAnimating];
	[self addSubview:self.activityIndicator];
	
	self.scrollView = [[WAGalleryImageScrollView alloc] initWithFrame:self.bounds];
	self.scrollView.minimumZoomScale = 1.0f;
	self.scrollView.maximumZoomScale = 4.0f;
	self.scrollView.showsHorizontalScrollIndicator = NO;
	self.scrollView.showsVerticalScrollIndicator = NO;
	self.scrollView.delegate = self;
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self addSubview:self.scrollView];

	self.imageView = [[WAImageView alloc] initWithFrame:self.scrollView.bounds];
	self.imageView.center = CGPointZero;
	self.imageView.autoresizingMask = UIViewAutoresizingNone;
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
  self.imageView.delegate = self;
	[self.scrollView addSubview:self.imageView];
	
	#if 0
	
		self.clipsToBounds = NO;
		self.scrollView.clipsToBounds = NO;
		self.imageView.clipsToBounds = NO;
		
		self.scrollView.layer.borderColor = [UIColor blueColor].CGColor;
		self.scrollView.layer.borderWidth = 2.0f;
		
		self.imageView.layer.borderColor = [UIColor greenColor].CGColor;
		self.imageView.layer.borderWidth = 1.0f;
	
	#endif
	
	self.needsContentAdjustmentOnLayout = YES;
	[self setNeedsLayout];
	
	self.exclusiveTouch = YES;
	
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

- (void) scrollViewDidZoom:(UIScrollView *)sv {

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

//	- (void) handleDoubleTap:(UITapGestureRecognizer *)aRecognizer {
//		
//		CGPoint locationInView = [aRecognizer locationInView:self];
//		CGPoint offsetFromCenter = (CGPoint) {
//			locationInView.x - CGRectGetMidX(self.bounds),
//			locationInView.y - CGRectGetMidY(self.bounds)
//		};
//
//		CGFloat scale = self.scrollView.zoomScale;
//		
//		__block CGFloat newScale = scale;
//		
//		[UIView animateWithDuration:0.3f animations: ^ {
//		
//			CGRect oldScrollViewBounds = self.scrollView.layer.bounds;
//			 
//			if (scale < 1) {
//				newScale = 1;
//			} else if (scale >= self.scrollView.maximumZoomScale) {
//				newScale = 1;
//			} else {
//				newScale = self.scrollView.maximumZoomScale;
//			}
//			
//			[self.scrollView setZoomScale:newScale animated:NO];
//			
//			self.needsInsetAdjustmentOnLayout = YES;
//			
//			if (newScale > 1) {
//			
//				newScale = MIN(newScale, 2);
//				
//				CGPoint newOffsetFromCenter = (CGPoint){
//					offsetFromCenter.x * (newScale / scale),
//					offsetFromCenter.y * (newScale / scale)
//				};
//				
//				CGPoint newContentOffset = (CGPoint){
//					self.scrollView.contentOffset.x + newOffsetFromCenter.x,
//					self.scrollView.contentOffset.y + newOffsetFromCenter.y
//				};
//				
//				self.scrollView.layer.bounds = oldScrollViewBounds;
//				[self.scrollView.layer removeAnimationForKey:@"bounds"];
//				
//				[self.scrollView setContentOffset:newContentOffset animated:NO];
//
//			} else {
//
//				self.needsContentAdjustmentOnLayout = YES;
//				self.needsOffsetAdjustmentOnLayout = YES;
//				
//				self.scrollView.layer.bounds = oldScrollViewBounds;
//				[self.scrollView.layer removeAnimationForKey:@"bounds"];
//
//				[self layoutSubviews];
//	 
//			}
//
//		} completion: ^ (BOOL finished) {
//		
//			//  ?
//			
//		}];
//
//	}

@end
