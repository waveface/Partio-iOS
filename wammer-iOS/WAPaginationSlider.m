//
//  WAPaginationSlider.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAPaginationSlider.h"


@interface WAPaginationSlider ()
@property (nonatomic, readwrite, retain) UISlider *slider; 
+ (UIImage *) transparentImage;
@end


@implementation WAPaginationSlider
@synthesize slider;
@synthesize dotRadius, dotMargin, delegate;

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
	
	self.dotRadius = 4.0f;
	self.dotMargin = 12.0f;
	
	self.slider = [[[UISlider alloc] initWithFrame:self.bounds] autorelease];
	self.slider.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.slider setMinimumTrackImage:[[self class] transparentImage] forState:UIControlStateNormal];
	[self.slider setMaximumTrackImage:[[self class] transparentImage] forState:UIControlStateNormal];
	[self addSubview:self.slider];
	
	return self;
	
}

- (void) layoutSubviews {

	for (UIView *aSubview in self.subviews)
		if (aSubview != self.slider)
			[aSubview removeFromSuperview];

	CGFloat ownWidth = CGRectGetWidth(self.frame);
	NSUInteger numberOfDots = (NSUInteger)floorf((ownWidth + self.dotMargin) / (self.dotRadius + self.dotMargin));
	CGFloat dotSpacing = (ownWidth + self.dotMargin) / numberOfDots;

	UIGraphicsBeginImageContextWithOptions((CGSize){ self.dotRadius, self.dotRadius }, NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [[UIColor blackColor] colorWithAlphaComponent:0.35f].CGColor);
	CGContextFillEllipseInRect(context, (CGRect){ 0, 0, self.dotRadius, self.dotRadius });
	UIImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	CGFloat offsetX = 0;
	CGFloat offsetY = roundf(0.5f * (CGRectGetHeight(self.bounds) - self.dotRadius));

	int i; for (i = 0; i < numberOfDots; i++) {
		
		UIView *tempTestingView = [[[UIView alloc] initWithFrame:(CGRect){ offsetX, offsetY, self.dotRadius, self.dotRadius }] autorelease];
		
		tempTestingView.layer.contents = (id)dotImage.CGImage;
		[self addSubview:tempTestingView];

		offsetX += dotSpacing;
		
	}
	
	[self bringSubviewToFront:self.slider];

}

- (void) dealloc {

	[slider release];
	
	[super dealloc];

}

@end
