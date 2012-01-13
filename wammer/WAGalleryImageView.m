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

	WAGalleryImageView *returnedView = [[[self alloc] init] autorelease];
	returnedView.image = image;
	return returnedView;

}

- (void) waInit {
	
	//	Host provides recognizer
	//	UITapGestureRecognizer *doubleTapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)] autorelease];
	//	doubleTapRecognizer.numberOfTapsRequired = 2;
	//	[self addGestureRecognizer:doubleTapRecognizer];

	self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
	self.activityIndicator.hidesWhenStopped = NO;
	self.activityIndicator.center = (CGPoint){
		CGRectGetMidX(self.bounds),
		CGRectGetMidY(self.bounds)
	};
	[self.activityIndicator startAnimating];
	[self addSubview:self.activityIndicator];
	
	self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
	self.scrollView.minimumZoomScale = 0.01;
	self.scrollView.maximumZoomScale = 4.0f;
	self.scrollView.showsHorizontalScrollIndicator = NO;
	self.scrollView.showsVerticalScrollIndicator = NO;
	self.scrollView.delegate = self;
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self addSubview:self.scrollView];

	self.imageView = [[[WAImageView alloc] initWithFrame:self.scrollView.bounds] autorelease];
	self.imageView.center = CGPointZero;
	self.imageView.autoresizingMask = UIViewAutoresizingNone;
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
  self.imageView.delegate = self;
	[self.scrollView addSubview:self.imageView];
	
	#if 0
	
		self.clipsToBounds = NO;
		self.scrollView.clipsToBounds = NO;
		self.imageView.clipsToBounds = NO;
		
		self.layer.borderColor = [UIColor redColor].CGColor;
		self.layer.borderWidth = 1.0f;
		
		self.scrollView.layer.borderColor = [UIColor blueColor].CGColor;
		self.scrollView.layer.borderWidth = 2.0f;
		
		self.imageView.layer.borderColor = [UIColor greenColor].CGColor;
		self.imageView.layer.borderWidth = 4.0f;
	
	#endif
	
	self.needsContentAdjustmentOnLayout = YES;
	[self setNeedsLayout];
	
	self.exclusiveTouch = YES;
	
}

- (void) imageViewDidUpdate:(WAImageView *)anImageView {

  [self layoutSubviews];
  [self setNeedsLayout];

}

- (void) setFrame:(CGRect)newFrame {

	BOOL frameChanged = !CGRectEqualToRect(self.frame, newFrame);

	[super setFrame:newFrame];
	
	if (frameChanged) {
	
		self.needsContentAdjustmentOnLayout = YES;
		self.needsInsetAdjustmentOnLayout = YES;
		self.needsOffsetAdjustmentOnLayout = YES;

		//	[self.scrollView setZoomScale:1 animated:NO];
		//	[self layoutSubviews];
		
		CGPoint oldOffset = self.scrollView.contentOffset;
		[self.scrollView setZoomScale:1 animated:NO];
		[self.scrollView setContentOffset:oldOffset animated:NO];
	
	}

}

- (void) setBounds:(CGRect)newBounds {

	BOOL boundsChanged = !CGRectEqualToRect(self.bounds, newBounds);

	[super setBounds:newBounds];

	if (boundsChanged) {

		self.needsContentAdjustmentOnLayout = YES;
		self.needsInsetAdjustmentOnLayout = YES;
		self.needsOffsetAdjustmentOnLayout = YES;

		//	[self.scrollView setZoomScale:1 animated:NO];
		//	[self layoutSubviews];
		
		CGPoint oldOffset = self.scrollView.contentOffset;
		[self.scrollView setZoomScale:1 animated:NO];
		[self.scrollView setContentOffset:oldOffset animated:NO];

	}

}

- (void) setImage:(UIImage *)newImage {

	[self setImage:newImage animated:NO];

}

- (void) setImage:(UIImage *)newImage animated:(BOOL)animate {

	[self setImage:newImage animated:animate synchronized:NO];

}

- (void) setImage:(UIImage *)newImage animated:(BOOL)animate synchronized:(BOOL)sync {

	if (self.imageView.image == newImage)
		return;

	void (^operations)() = ^ {
		
    [self willChangeValueForKey:@"image"];
		[self.imageView setImage:newImage withOptions:(sync ? WAImageViewForceSynchronousOption : WAImageViewForceAsynchronousOption)];
		self.imageView.bounds = (CGRect) { CGPointZero, newImage.size } ;
		self.activityIndicator.hidden = !!(newImage);
    
    self.needsContentAdjustmentOnLayout = YES;
    self.needsInsetAdjustmentOnLayout = YES;
    self.needsOffsetAdjustmentOnLayout = YES;
    [self setNeedsLayout];
    
		[self didChangeValueForKey:@"image"];
    
	};

	if (animate) {
	
		[UIView transitionWithView:self duration:0.3f options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction animations:operations completion:nil];
	
	} else {
	
		operations();
	
	}

}

- (UIImage *) image {

	return self.imageView.image;

}

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)aScrollView {

	return self.imageView;

}

- (void) scrollViewDidZoom:(UIScrollView *)aScrollView {

	[self.delegate galleryImageViewDidBeginInteraction:self];
  
  UIPinchGestureRecognizer *svPinchGestureRecognizer = ((^ {
  
    if ([aScrollView respondsToSelector:@selector(pinchGestureRecognizer)])
      return [aScrollView pinchGestureRecognizer];
    
    return (UIPinchGestureRecognizer *)[[aScrollView.gestureRecognizers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
      return [evaluatedObject isKindOfClass:[UIPinchGestureRecognizer class]];
    }]] lastObject];
  
  })());
  
  if (svPinchGestureRecognizer)
  if (svPinchGestureRecognizer.state == UIGestureRecognizerStateChanged)
  if (aScrollView.zoomScale < 1) {
  
    CGPoint centroid = [svPinchGestureRecognizer locationInView:aScrollView];
    self.imageView.center = centroid;
  
  }

}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {

	[self.delegate galleryImageViewDidBeginInteraction:self];

}

- (void) scrollViewDidEndZooming:(UIScrollView *)aScrollView withView:(UIView *)view atScale:(float)scale {
	
	[UIView animateWithDuration:0.3f animations: ^ {

		if (scale > 1) {
	
			CGRect scrollViewBounds = self.scrollView.bounds;
			CGRect imageViewFrame = self.imageView.frame;
			
			aScrollView.contentInset = (UIEdgeInsets){
				MAX(0, 0.5f * (CGRectGetHeight(scrollViewBounds) - CGRectGetHeight(imageViewFrame))),
				MAX(0, 0.5f * (CGRectGetWidth(scrollViewBounds) - CGRectGetWidth(imageViewFrame))),
				0,
				0
			};
			
			[self layoutSubviews];
			
		} else {
    
      CGRect oldScrollViewBounds = self.scrollView.layer.bounds;
		
			self.needsContentAdjustmentOnLayout = YES;
			[aScrollView setZoomScale:1 animated:NO];
			[self layoutSubviews];
      
      self.scrollView.layer.bounds = oldScrollViewBounds;
      [self.scrollView.layer removeAnimationForKey:@"bounds"];
      
      [self layoutSubviews];
		
		}

	}];

}

- (void) handleDoubleTap:(UITapGestureRecognizer *)aRecognizer {
  
	CGPoint locationInView = [aRecognizer locationInView:self];
	CGPoint offsetFromCenter = (CGPoint) {
		locationInView.x - CGRectGetMidX(self.bounds),
		locationInView.y - CGRectGetMidY(self.bounds)
	};

	CGFloat scale = self.scrollView.zoomScale;
	
  __block CGFloat newScale = scale;
  
	[UIView animateWithDuration:0.3f animations: ^ {
  
    CGRect oldScrollViewBounds = self.scrollView.layer.bounds;
     
		if (scale < 1) {
      newScale = 1;
    } else if (scale >= self.scrollView.maximumZoomScale) {
      newScale = 1;
		} else {
      newScale = self.scrollView.maximumZoomScale;
    }
		
    [self.scrollView setZoomScale:newScale animated:NO];
    
    self.needsInsetAdjustmentOnLayout = YES;
    
    if (newScale > 1) {
    
      newScale = MIN(newScale, 2);
      
      CGPoint newOffsetFromCenter = (CGPoint){
        offsetFromCenter.x * (newScale / scale),
        offsetFromCenter.y * (newScale / scale)
      };
      
      CGPoint newContentOffset = (CGPoint){
        self.scrollView.contentOffset.x + newOffsetFromCenter.x,
        self.scrollView.contentOffset.y + newOffsetFromCenter.y
      };
      
      self.scrollView.layer.bounds = oldScrollViewBounds;
      [self.scrollView.layer removeAnimationForKey:@"bounds"];
      
      [self.scrollView setContentOffset:newContentOffset animated:NO];

    } else {

      self.needsContentAdjustmentOnLayout = YES;
      self.needsOffsetAdjustmentOnLayout = YES;
      
      self.scrollView.layer.bounds = oldScrollViewBounds;
      [self.scrollView.layer removeAnimationForKey:@"bounds"];

      [self layoutSubviews];
 
    }

	} completion: ^ (BOOL finished) {
  
    //  ?
    
  }];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	if (!self.image)
		return;
	
	id currentDelegate = self.delegate;
	delegate = nil;
	
	CGRect scrollViewBounds = self.bounds;
	CGRect presumedImageRect = IRGravitize(scrollViewBounds, self.image.size, kCAGravityResizeAspect);
	
	if (self.needsContentAdjustmentOnLayout) {
	
		CGRect oldImageViewBounds = self.imageView.bounds;
		CGPoint oldImageViewCenter = self.imageView.center;
		CGSize oldScrollViewContentSize = self.scrollView.contentSize;
		
		CGRect newImageViewBounds = (CGRect){
			CGPointZero,
			presumedImageRect.size
			//	(self.scrollView.zoomScale > 1) ? presumedImageRect.size : scrollViewBounds.size
		};
		
		CGPoint newImageViewCenter = (CGPoint){
			CGRectGetMidX(newImageViewBounds),
			CGRectGetMidY(newImageViewBounds)
		};
		
		CGSize newScrollViewContentSize = newImageViewBounds.size;
		
		if (!CGRectEqualToRect(oldImageViewBounds, newImageViewBounds))
			self.imageView.bounds = newImageViewBounds;
		
		if (!CGPointEqualToPoint(oldImageViewCenter, newImageViewCenter))
			self.imageView.center = newImageViewCenter;
		
		if (!CGSizeEqualToSize(oldScrollViewContentSize, newScrollViewContentSize))
			self.scrollView.contentSize = newScrollViewContentSize;
		
	}
	
	if (self.needsContentAdjustmentOnLayout || self.needsInsetAdjustmentOnLayout) {

		UIEdgeInsets oldContentInset = self.scrollView.contentInset;
		UIEdgeInsets newContentInset = oldContentInset;
	
		if (self.scrollView.zoomScale > 1) {
		
			newContentInset = UIEdgeInsetsZero;
		
		} else {

			newContentInset = (UIEdgeInsets) {
				0.5f * (CGRectGetHeight(scrollViewBounds) - CGRectGetHeight(presumedImageRect)),
				0.5f * (CGRectGetWidth(scrollViewBounds) - CGRectGetWidth(presumedImageRect)),
				-0.5f * (CGRectGetHeight(scrollViewBounds) - CGRectGetHeight(presumedImageRect)),
				-0.5f * (CGRectGetWidth(scrollViewBounds) - CGRectGetWidth(presumedImageRect))
			};
	
		}
		
		if (!UIEdgeInsetsEqualToEdgeInsets(oldContentInset, newContentInset)) {
			self.scrollView.contentInset = newContentInset;
		}
		
	};
	
	if (self.needsContentAdjustmentOnLayout || self.needsOffsetAdjustmentOnLayout) {
	
		CGPoint oldContentOffset = self.scrollView.contentOffset;
		CGPoint newContentOffset = oldContentOffset;
	
		if (self.scrollView.zoomScale <= 1) {
			
			newContentOffset = (CGPoint){
			
				-1 * self.scrollView.contentInset.left,
				-1 * self.scrollView.contentInset.top
			
			};

		}
		
		if (!CGPointEqualToPoint(oldContentOffset, newContentOffset)) {
			self.scrollView.contentOffset = newContentOffset;
		}
	
	}
	
	self.needsContentAdjustmentOnLayout = NO;
	self.needsInsetAdjustmentOnLayout = NO;
	self.needsOffsetAdjustmentOnLayout = NO;
	delegate = currentDelegate;
	
}

- (void) reset {

	self.needsContentAdjustmentOnLayout = YES;
	self.needsOffsetAdjustmentOnLayout = YES;
	self.needsInsetAdjustmentOnLayout = YES;
	
	if (self.scrollView.decelerating || self.scrollView.tracking || self.scrollView.dragging || self.scrollView.zoomBouncing || self.scrollView.zooming)
		self.revertsOnZoomEnd = YES;
	else
		[self.scrollView setZoomScale:1 animated:NO];
	
	self.needsContentAdjustmentOnLayout = YES;
	self.needsOffsetAdjustmentOnLayout = YES;
	self.needsInsetAdjustmentOnLayout = YES;
	
	[self setNeedsLayout];

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

- (void) dealloc {

  imageView.delegate = nil;

	[activityIndicator release];
	[imageView release];
	[scrollView release];

	[super dealloc];
	
}

@end
