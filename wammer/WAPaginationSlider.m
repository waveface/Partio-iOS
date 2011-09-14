//
//  WAPaginationSlider.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAPaginationSlider.h"


@interface WAPaginationSlider ()
@property (nonatomic, readwrite, retain) UISlider *slider; 
@property (nonatomic, readwrite, retain) UILabel *pageIndicatorLabel; 
+ (UIImage *) transparentImage;
- (void) sharedInit;
@end


@implementation WAPaginationSlider
@synthesize slider;
@synthesize dotRadius, dotMargin, edgeInsets, numberOfPages, currentPage, snapsToPages, delegate;
@synthesize pageIndicatorLabel;

+ (UIImage *) transparentImage {

	static UIImage *returnedImage = nil;
	static dispatch_once_t onceToken = 0;
	
	dispatch_once(&onceToken, ^ {
    
		UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
		returnedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		[returnedImage retain];
			
	});

	return returnedImage;

}

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	
	if (!self)
		return nil;
	
	[self sharedInit];
				
	return self;
	
}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	[self sharedInit];

}

- (void) sharedInit {

	self.dotRadius = 4.0f;
	self.dotMargin = 12.0f;
	self.edgeInsets = (UIEdgeInsets){ 0, 12, 0, 12 };
	
	self.numberOfPages = 24;
	self.currentPage = 0;
	self.snapsToPages = YES;
	
	self.slider = [[[UISlider alloc] initWithFrame:self.bounds] autorelease];
	self.slider.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.slider setMinimumTrackImage:[[self class] transparentImage] forState:UIControlStateNormal];
	[self.slider setMaximumTrackImage:[[self class] transparentImage] forState:UIControlStateNormal];
	[self.slider addTarget:self action:@selector(sliderDidMove:) forControlEvents:UIControlEventValueChanged];
	[self.slider addTarget:self action:@selector(sliderTouchDidStart:) forControlEvents:UIControlEventTouchDown];
	[self.slider addTarget:self action:@selector(sliderTouchDidEnd:) forControlEvents:UIControlEventTouchUpInside];
	[self.slider addTarget:self action:@selector(sliderTouchDidEnd:) forControlEvents:UIControlEventTouchUpOutside];
	
	self.pageIndicatorLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	self.pageIndicatorLabel.font = [UIFont boldSystemFontOfSize:14.0f];
	self.pageIndicatorLabel.textColor = [UIColor whiteColor];
	self.pageIndicatorLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
	self.pageIndicatorLabel.opaque = NO;
	self.pageIndicatorLabel.alpha = 0;
	self.pageIndicatorLabel.userInteractionEnabled = NO;
	self.pageIndicatorLabel.textAlignment = UITextAlignmentCenter;
	self.pageIndicatorLabel.layer.cornerRadius = 4.0f;
	
	[self addSubview:self.slider];
	[self addSubview:self.pageIndicatorLabel];

}

- (void) layoutSubviews {

	static int dotTag = 1048576;

	NSMutableSet *dequeuedDots = [NSMutableSet set];

	for (UIView *aSubview in self.subviews)
		if (aSubview.tag == dotTag)
			[dequeuedDots addObject:aSubview];

	CGFloat usableWidth = CGRectGetWidth(self.bounds) - self.edgeInsets.left - self.edgeInsets.right;
	NSUInteger numberOfDots = MIN(self.numberOfPages, (NSUInteger)floorf(usableWidth / (self.dotRadius + self.dotMargin)));
	CGFloat dotSpacing = usableWidth / (numberOfDots - 1);
	
	UIImage *dotImage = (( ^ (CGFloat radius, CGFloat alpha) {
	
		UIGraphicsBeginImageContextWithOptions((CGSize){ radius, radius }, NO, 0.0f);
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(context, [[UIColor blackColor] colorWithAlphaComponent:alpha].CGColor);
		CGContextFillEllipseInRect(context, (CGRect){ 0, 0, radius, radius });
		UIImage *returnedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return returnedImage;
	
	})(self.dotRadius, 0.35f));
	
	NSInteger numberOfRequiredNewDots = numberOfDots - [dequeuedDots count];
	
	if (numberOfRequiredNewDots)
	for (int i = 0; i < numberOfRequiredNewDots; i++) {
		UIView *dotView = [[[UIView alloc] initWithFrame:(CGRect){ 0, 0, self.dotRadius, self.dotRadius }] autorelease];
		dotView.tag = dotTag;
		dotView.layer.contents = (id)dotImage.CGImage;
		[dequeuedDots addObject:dotView];
	}
	
	CGFloat offsetX = self.edgeInsets.left - 0.5 * self.dotRadius;
	CGFloat offsetY = roundf(0.5f * (CGRectGetHeight(self.bounds) - self.dotRadius));

	int i; for (i = 0; i < numberOfDots; i++) {
	
		UIView *dotView = [[(UIView *)[dequeuedDots anyObject] retain] autorelease];
		[dequeuedDots removeObject:dotView];
		
		dotView.frame = (CGRect){ roundf(offsetX), roundf(offsetY), self.dotRadius, self.dotRadius }; 
		[self addSubview:dotView];
		
		offsetX += dotSpacing;
		
	}
	
	for (UIView *unusedDotView in dequeuedDots)
		[unusedDotView removeFromSuperview];
	
	[self bringSubviewToFront:self.slider];

}

- (NSUInteger) estimatedPageNumberForPosition:(CGFloat)aPosition {

	if (!self.numberOfPages)
		return 0;
		
	CGFloat roughEstimation = ((self.numberOfPages - 1) * aPosition);
	
	if (roughEstimation == 0)
		return (NSUInteger)floorf(roughEstimation);
	else if (roughEstimation == (self.numberOfPages - 1))
		return (NSUInteger)ceilf(roughEstimation);
	else
		return (NSUInteger)roundf(roughEstimation);

}

- (CGFloat) positionForPageNumber:(NSUInteger)aPageNumber {

	return (CGFloat)(1.0f * aPageNumber / (self.numberOfPages - 1));

}

- (void) sliderTouchDidStart:(UISlider *)aSlider {

	[self willChangeValueForKey:@"currentPage"];
	currentPage = [self estimatedPageNumberForPosition:aSlider.value];
	[self didChangeValueForKey:@"currentPage"];
	
	self.pageIndicatorLabel.text = [NSString stringWithFormat:@"%i of %i", (self.currentPage + 1), self.numberOfPages];
	[self.pageIndicatorLabel sizeToFit];
	self.pageIndicatorLabel.frame = UIEdgeInsetsInsetRect(self.pageIndicatorLabel.frame, (UIEdgeInsets){ -4, -4, -4, -4 });
	self.pageIndicatorLabel.center = (CGPoint){ CGRectGetMidX(self.bounds), -12.0f };
	
	[UIView animateWithDuration:0.125f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionAllowUserInteraction animations: ^ {
		
		self.pageIndicatorLabel.alpha = 1.0f;
	
	} completion:nil];

}

- (void) sliderDidMove:(UISlider *)aSlider {

	[self willChangeValueForKey:@"currentPage"];
	currentPage = [self estimatedPageNumberForPosition:aSlider.value];
	[self didChangeValueForKey:@"currentPage"];
	
	self.pageIndicatorLabel.text = [NSString stringWithFormat:@"%i of %i", (self.currentPage + 1), self.numberOfPages];
	[self.pageIndicatorLabel sizeToFit];
	self.pageIndicatorLabel.frame = UIEdgeInsetsInsetRect(self.pageIndicatorLabel.frame, (UIEdgeInsets){ -4, -4, -4, -4 });
	self.pageIndicatorLabel.center = (CGPoint){ CGRectGetMidX(self.bounds), -12.0f };

}

- (void) sliderTouchDidEnd:(UISlider *)aSlider {

	[self willChangeValueForKey:@"currentPage"];
	currentPage = [self estimatedPageNumberForPosition:aSlider.value];
	[self didChangeValueForKey:@"currentPage"];
		
	[UIView animateWithDuration:0.125f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionLayoutSubviews|UIViewAnimationOptionAllowUserInteraction animations: ^ {
		
		self.pageIndicatorLabel.alpha = 0.0f;
	
	} completion:nil];
	
	NSUInteger capturedCurrentPage = self.currentPage;
	dispatch_async(dispatch_get_current_queue(), ^ {
	
		CGFloat inferredSliderSnappingValue = [self positionForPageNumber:capturedCurrentPage];
		[self.delegate paginationSlider:self didMoveToPage:capturedCurrentPage];
		
		if (self.snapsToPages)
			[aSlider setValue:inferredSliderSnappingValue animated:YES];
		
	});

}

- (void) setCurrentPage:(NSUInteger)newPage {

	[self setCurrentPage:newPage animated:YES];

}

- (void) setCurrentPage:(NSUInteger)newPage animated:(BOOL)animate {

	if (currentPage == newPage)
		return;
	
	[self willChangeValueForKey:@"currentPage"];
	
	currentPage = newPage;
	
	if (![self.slider isTracking])
		[self.slider setValue:[self positionForPageNumber:newPage] animated:animate];
	
	[self didChangeValueForKey:@"currentPage"];

}

- (void) dealloc {

	[slider release];
	
	[super dealloc];

}

@end
