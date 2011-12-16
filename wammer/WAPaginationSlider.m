//
//  WAPaginationSlider.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <objc/runtime.h>

#import "WAPaginationSlider.h"


@interface WAPaginationSlider ()
@property (nonatomic, readwrite, retain) UISlider *slider; 
@property (nonatomic, readwrite, retain) UILabel *pageIndicatorLabel; 
@property (nonatomic, readwrite, retain) NSArray *annotations;
+ (UIImage *) transparentImage;
- (void) sharedInit;
- (NSMutableArray *) mutableAnnotations;
- (CGFloat) positionForPageNumber:(NSUInteger)aPageNumber;
@property (nonatomic, readwrite, assign) BOOL needsAnnotationsLayout;
@end


@implementation WAPaginationSlider
@synthesize slider;
@synthesize dotRadius, dotMargin, edgeInsets, numberOfPages, currentPage, snapsToPages, delegate;
@synthesize pageIndicatorLabel;
@synthesize instantaneousCallbacks;
@synthesize layoutStrategy;
@synthesize annotations, needsAnnotationsLayout;

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

- (void) dealloc {

	[slider release];
	[annotations release];
	
	[super dealloc];

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

	self.annotations = [NSArray array];

	self.dotRadius = 3.0f;
	self.dotMargin = 12.0f;
	self.edgeInsets = (UIEdgeInsets){ 0, 12, 0, 12 };
	
	self.numberOfPages = 24;
	self.currentPage = 0;
	self.snapsToPages = YES;
	
	self.slider = [[[UISlider alloc] initWithFrame:self.bounds] autorelease];
	self.slider.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	[self.slider setMinimumTrackImage:[[self class] transparentImage] forState:UIControlStateNormal];
	[self.slider setMaximumTrackImage:[[self class] transparentImage] forState:UIControlStateNormal];
	[self.slider setThumbImage:[UIImage imageNamed:@"WAPageSliderThumbInactive"] forState:UIControlStateDisabled];
	[self.slider setThumbImage:[UIImage imageNamed:@"WAPageSliderThumb"] forState:UIControlStateNormal];
	[self.slider setThumbImage:[UIImage imageNamed:@"WAPageSliderThumbActive"] forState:UIControlStateSelected];
	[self.slider setThumbImage:[UIImage imageNamed:@"WAPageSliderThumbActive"] forState:UIControlStateHighlighted];
	
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
	
	[self setNeedsLayout];

}

- (void) setNumberOfPages:(NSUInteger)newNumberOfPages {

	if (numberOfPages == newNumberOfPages)
		return;
	
	[self willChangeValueForKey:@"numberOfPages"];
	numberOfPages = newNumberOfPages;
	[self didChangeValueForKey:@"numberOfPages"];
	
	[self.slider setValue:[self positionForPageNumber:self.currentPage] animated:YES];
	
	[self setNeedsLayout];

}

- (void) setBounds:(CGRect)bounds {

	self.needsAnnotationsLayout = YES;
	[super setBounds:bounds];

}

- (void) setFrame:(CGRect)frame {

	self.needsAnnotationsLayout = YES;
	[super setFrame:frame];

}

- (void) layoutSubviews {

	static int dotTag = 1048576;
	static int annotationViewTag = 2097152;
	
	NSMutableSet *dequeuedDots = [NSMutableSet set];
	
	self.slider.enabled = !!self.numberOfPages;

	for (UIView *aSubview in self.subviews)
		if (aSubview.tag == dotTag)
			[dequeuedDots addObject:aSubview];

	CGFloat usableWidth = CGRectGetWidth(self.bounds) - self.edgeInsets.left - self.edgeInsets.right;
	NSUInteger numberOfDots = (NSUInteger)floorf(usableWidth / (self.dotRadius + self.dotMargin));
	
	switch (self.layoutStrategy) {
		
		case WAPaginationSliderFillWithDotsLayoutStrategy: {
			break;
		}
		
		case WAPaginationSliderLessDotsLayoutStrategy: {
		
			if (self.numberOfPages)
				numberOfDots = MIN(numberOfDots, self.numberOfPages);
		
			break;
		}
		
	}
	
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
		[self insertSubview:dotView belowSubview:slider];
		
		offsetX += dotSpacing;
		
	}
	
	for (UIView *unusedDotView in dequeuedDots)
		[unusedDotView removeFromSuperview];
	
	[self bringSubviewToFront:self.slider];
	
	NSString * const kWAPaginationSliderAnnotationView_HostAnnotation = @"WAPaginationSliderAnnotationView_HostAnnotation";
	
	for (UIView *aSubview in self.subviews) {
		if (aSubview.tag == annotationViewTag) {
			if (![self.annotations containsObject:objc_getAssociatedObject(aSubview, kWAPaginationSliderAnnotationView_HostAnnotation)]) {
				[aSubview removeFromSuperview];
			}
		}
	}
	
	for (WAPaginationSliderAnnotation *anAnnotation in self.annotations) {
		
		NSArray *allFittingAnnotationViews = [self.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (UIView *anAnnotationView, NSDictionary *bindings) {
			
			if (anAnnotationView.tag != annotationViewTag)
				return NO;
			
			if (anAnnotation == objc_getAssociatedObject(anAnnotationView, kWAPaginationSliderAnnotationView_HostAnnotation))
				return YES;
			
			return NO;
			
		}]];
		
		NSParameterAssert([allFittingAnnotationViews count] <= 1);
		
		UIView *annotationView = [allFittingAnnotationViews lastObject];
		
		if (!annotationView)
			annotationView = [self.delegate viewForAnnotation:anAnnotation inPaginationSlider:self];
		
		NSParameterAssert(annotationView);
		
		annotationView.center = (CGPoint){
			anAnnotation.centerOffset.x + self.edgeInsets.left + roundf(usableWidth * [self positionForPageNumber:anAnnotation.pageIndex]),
			anAnnotation.centerOffset.y + roundf(0.5f * CGRectGetHeight(self.bounds))
		};
		
		if (annotationView.superview != self)
			[self insertSubview:annotationView belowSubview:slider];
		
	}

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

	if (!aPageNumber)
		return 0;

	return (CGFloat)(1.0f * aPageNumber / (self.numberOfPages - 1));

}

- (void) sliderTouchDidStart:(UISlider *)aSlider {

	[self willChangeValueForKey:@"currentPage"];
	currentPage = [self estimatedPageNumberForPosition:aSlider.value];
	[self didChangeValueForKey:@"currentPage"];
	
	self.pageIndicatorLabel.text = [NSString stringWithFormat:@"%i of %i", (self.currentPage + 1), self.numberOfPages];
	[self.pageIndicatorLabel sizeToFit];
	self.pageIndicatorLabel.frame = UIEdgeInsetsInsetRect(self.pageIndicatorLabel.frame, (UIEdgeInsets){ -4, -4, -4, -4 });

	CGRect prospectiveThumbRect = [self.slider thumbRectForBounds:self.slider.bounds trackRect:[self.slider trackRectForBounds:self.slider.bounds] value:self.slider.value];
	self.pageIndicatorLabel.center = (CGPoint){ CGRectGetMidX(prospectiveThumbRect), -12.0f };
	
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
	
	CGRect prospectiveThumbRect = [self.slider thumbRectForBounds:self.slider.bounds trackRect:[self.slider trackRectForBounds:self.slider.bounds] value:self.slider.value];
	self.pageIndicatorLabel.center = (CGPoint){ CGRectGetMidX(prospectiveThumbRect), -12.0f };
	
	if (instantaneousCallbacks)
		[self.delegate paginationSlider:self didMoveToPage:currentPage];
	
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
	
	[self setNeedsLayout];

}

- (NSMutableArray *) mutableAnnotations {

	return [self mutableArrayValueForKey:@"annotations"];

}

- (void) addAnnotations:(NSSet *)insertedAnnotations {

	[[self mutableAnnotations] addObjectsFromArray:[insertedAnnotations allObjects]];
	[self setNeedsLayout];

}

- (void) addAnnotationsObject:(WAPaginationSliderAnnotation *)anAnnotation {

	[[self mutableAnnotations] addObject:anAnnotation];
	[self setNeedsLayout];

}

- (void) removeAnnotations:(NSSet *)removedAnnotations {

	[[self mutableAnnotations] removeObjectsInArray:[removedAnnotations allObjects]];
	[self setNeedsLayout];

}

- (void) removeAnnotationsAtIndexes:(NSIndexSet *)indexes {

	[[self mutableAnnotations] removeObjectsAtIndexes:indexes];
	[self setNeedsLayout];

}

- (void) removeAnnotationsObject:(WAPaginationSliderAnnotation *)anAnnotation {

	[[self mutableAnnotations] removeObject:anAnnotation];
	[self setNeedsLayout];

}

@end





@implementation WAPaginationSliderAnnotation : NSObject
@synthesize title, pageIndex, centerOffset;

- (void) dealloc {

	[title release];
	[super dealloc];

}

@end