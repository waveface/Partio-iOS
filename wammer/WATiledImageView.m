//
//  WATiledImageView.m
//  wammer
//
//  Created by Evadne Wu on 12/13/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WATiledImageView.h"

#import <QuartzCore/QuartzCore.h> 
#import <objc/runtime.h>

#import "WAImageView.h"
#import "UIImage+IRAdditions.h"
#import "CGGeometry+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"


static NSString * const kWATiledImageView_storedImage = @"kWAImageView_storedImage";


@interface WATiledImageViewLayer : CATiledLayer

@property (nonatomic, readwrite, copy) void (^onContentsGravityChanged)(NSString *newGravity);

@end

@implementation WATiledImageViewLayer
@synthesize onContentsGravityChanged;

+ (NSTimeInterval) fadeDuration {

	return 0.0f;

}

- (void) setContentsGravity:(NSString *)newGravity {

	[super setContentsGravity:newGravity];

	if (self.onContentsGravityChanged)
		self.onContentsGravityChanged(newGravity);

}

@end


@interface WAImageViewContentView : UIView
@end

@implementation WAImageViewContentView 

+ (Class) layerClass {

	return [WATiledImageViewLayer class];

}

- (void) drawLayer:(CATiledLayer *)layer inContext:(CGContextRef)ctx {

	UIImage *ownImage = objc_getAssociatedObject(layer, &kWATiledImageView_storedImage);
	if (!ownImage)
		return;
	
	CGRect rect = layer.bounds;//CGContextGetClipBoundingBox(ctx);
	
	CGSize imageSize = ownImage.size;
	if (!(imageSize.width * imageSize.height))
		return;
		
	CGContextScaleCTM(ctx, layer.contentsScale, layer.contentsScale);
	
	CGContextSaveGState(ctx);
	CGContextTranslateCTM(ctx, 0, rect.size.height);
	CGContextScaleCTM(ctx, 1, -1);
	CGContextDrawImage(ctx, rect, ownImage.CGImage);
	CGContextRestoreGState(ctx);

}

- (void) setBounds:(CGRect)newBounds {

	CGRect oldBounds = self.bounds;
	[super setBounds:newBounds];
	
	if (!CGRectEqualToRect(oldBounds, newBounds))
		[self setNeedsLayout];
		
}

- (void) layoutSubviews {

	[super layoutSubviews];

	UIImage *ownImage = objc_getAssociatedObject(self.layer, &kWATiledImageView_storedImage);
	if (!ownImage)
		return;

	if (!CGSizeEqualToSize(ownImage.size, ((CATiledLayer *)self.layer).tileSize)) {
	
		//	UIScreen *usedScreen = self.window.screen;
		//	if (!usedScreen)
		//		usedScreen = [UIScreen mainScreen];
		
		((CATiledLayer *)self.layer).tileSize = (CGSize){
		
			ownImage.size.width,
			ownImage.size.height
		
		};
		
	}

}

@end


@interface WATiledImageView ()
@property (nonatomic, readwrite, retain) WAImageViewContentView *contentView;
@end

@implementation WATiledImageView
@synthesize image, contentView;

- (WAImageViewContentView *) contentView {

	if (!contentView) {
		
		contentView = [[WAImageViewContentView alloc] initWithFrame:self.bounds];
		contentView.backgroundColor = nil;
		contentView.opaque = NO;
		contentView.autoresizingMask = UIViewAutoresizingNone;
				
		[self addSubview:contentView];
		
	}
	
	return contentView;

}

+ (Class) layerClass {

	return [WATiledImageViewLayer class];

}

- (void) drawRect:(CGRect)rect {

	//	NO OP

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	//	self.contentView.hidden = !image;
	if (!image)
		return;
		
	CGRect imageFrame = IRGravitize(self.bounds, self.image.size, self.layer.contentsGravity);
	
	self.contentView.center = (CGPoint){
		CGRectGetMidX(self.bounds),
		CGRectGetMidY(self.bounds)
	};
	
	self.contentView.layer.transform = CATransform3DMakeScale(
		imageFrame.size.width / self.image.size.width,
		imageFrame.size.height / self.image.size.height,
		1
	);
	
}

- (void) setImage:(UIImage *)newImage {

	NSParameterAssert([NSThread isMainThread]);

	if (newImage && (newImage == self.image))
		return;
	
	image = newImage;
	
	self.layer.contents = nil;
	
	if (newImage) {
	
		self.contentView.bounds = (CGRect){
			CGPointZero,
			self.image.size
		};
		
		objc_setAssociatedObject(self.contentView.layer, &kWATiledImageView_storedImage, newImage, OBJC_ASSOCIATION_RETAIN);
		[self.contentView.layer setNeedsDisplay];
		[self setNeedsLayout];
	
	} else {
	
		objc_setAssociatedObject(self.contentView.layer, &kWATiledImageView_storedImage, nil, OBJC_ASSOCIATION_ASSIGN);
		[self.contentView.layer setNeedsDisplay];
	
	}
	
	[self setNeedsLayout];

}

@end
