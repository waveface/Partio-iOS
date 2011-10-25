//
//  WAImageView.m
//  wammer
//
//  Created by Evadne Wu on 9/30/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <QuartzCore/QuartzCore.h> 
#import <objc/runtime.h>

#import "WAImageView.h"
#import "UIImage+IRAdditions.h"
#import "CGGeometry+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"


static NSString * const kWAImageView_storedImage = @"kWAImageView_storedImage";


@interface WAImageViewTiledLayer : CATiledLayer

@property (nonatomic, readwrite, copy) void (^onContentsGravityChanged)(NSString *newGravity);

@end

@implementation WAImageViewTiledLayer
@synthesize onContentsGravityChanged;

- (void) dealloc {

	[onContentsGravityChanged release];
	[super dealloc];

}

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

	return [WAImageViewTiledLayer class];

}

- (void) drawLayer:(CATiledLayer *)layer inContext:(CGContextRef)ctx {

	UIImage *ownImage = objc_getAssociatedObject(layer, &kWAImageView_storedImage);
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

- (void) setFrame:(CGRect)newFrame {

	if (CGRectEqualToRect(newFrame, self.frame))
		return;
	
	[super setFrame:newFrame];
	[self setNeedsLayout];
		
}

- (void) layoutSubviews {

	[super layoutSubviews];

	if (!CGSizeEqualToSize(self.bounds.size, ((CATiledLayer *)self.layer).tileSize)) {
	
		UIScreen *usedScreen = self.window.screen;
		if (!usedScreen)
			usedScreen = [UIScreen mainScreen];
		
		((CATiledLayer *)self.layer).tileSize = (CGSize){
			self.bounds.size.width * usedScreen.scale,
			self.bounds.size.height * usedScreen.scale
		};
		
	}

}

@end


@interface WAImageView ()
@property (nonatomic, readwrite, retain) WAImageViewContentView *contentView;
@end

@implementation WAImageView
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

- (void) dealloc {

	[image release];
	[contentView release];
	[super dealloc];

}

+ (Class) layerClass {

	return [WAImageViewTiledLayer class];

}

- (void) drawRect:(CGRect)rect {

	//	NO OP

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	self.contentView.hidden = !image;
	if (!image)
		return;
		
	CGRect imageFrame = IRGravitize(self.bounds, self.image.size, self.layer.contentsGravity);
	
	self.contentView.bounds = (CGRect){
		(CGPoint){
			0, 0 //CGRectGetMidX(self.bounds) - 0.5f * self.image.size.width,
			//CGRectGetMidY(self.bounds) - 0.5f * self.image.size.height
		},
		self.image.size
	};
	
	self.contentView.center = (CGPoint){
		CGRectGetMidX(self.bounds),
		CGRectGetMidY(self.bounds)
	};
	
	self.contentView.layer.transform = CATransform3DMakeScale(
		imageFrame.size.width / self.image.size.width,
		imageFrame.size.height / self.image.size.height,
		1
	);
	
	
	//imageFrame;

}

- (void) setImage:(UIImage *)newImage {

	if (newImage && (newImage == self.image))
		return;
	
	[self willChangeValueForKey:@"image"];
	[image release];
	image = [newImage retain];
	[self didChangeValueForKey:@"image"];
	
	self.layer.contents = nil;
	
	if (newImage) {
	
		//	self.contentView.frame = (CGRect){ CGPointZero, newImage.size };
		objc_setAssociatedObject(self.contentView.layer, &kWAImageView_storedImage, newImage, OBJC_ASSOCIATION_RETAIN);
		[self setNeedsLayout];
	
	} else {
	
		objc_setAssociatedObject(self.contentView.layer, &kWAImageView_storedImage, nil, OBJC_ASSOCIATION_ASSIGN);
	
	}
	
	[self setNeedsLayout];

}

@end
