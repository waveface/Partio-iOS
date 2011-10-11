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

	return 0.25f;

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

- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {

	UIImage *ownImage = objc_getAssociatedObject(layer, &kWAImageView_storedImage);
	if (!ownImage)
		return;
	
	CGSize imageSize = ownImage.size;
	if (!(imageSize.width * imageSize.height))
		return;
	
	CGRect layerFrame = layer.frame;
	CGRect imageFrame = layer.bounds;
	
	NSString *layerGravity = layer.contentsGravity;
	
	CGRect (^gravitize) (CGRect, CGSize, NSString *) = ^ (CGRect enclosingRect, CGSize contentSize, NSString *gravity) {
	
		CGRect (^align)(IRAnchor) = ^ (IRAnchor anAnchor) {
			return IRCGRectAlignToRect((CGRect){ CGPointZero, contentSize }, enclosingRect, anAnchor, YES);
		};
	
		if ([gravity isEqualToString:kCAGravityTopLeft])
			return align(irTopLeft);
		
		if ([gravity isEqualToString:kCAGravityTop])
			return align(irTop);
		
		if ([gravity isEqualToString:kCAGravityTopRight])
			return align(irTopRight);
		
		if ([gravity isEqualToString:kCAGravityLeft])
			return align(irLeft);
			
		if ([gravity isEqualToString:kCAGravityCenter])
			return align(irCenter);
		
		if ([gravity isEqualToString:kCAGravityRight])
			return align(irRight);
			
		if ([gravity isEqualToString:kCAGravityBottomLeft])
			return align(irBottomLeft);
		
		if ([gravity isEqualToString:kCAGravityBottom])
			return align(irBottom);
		
		if ([gravity isEqualToString:kCAGravityBottomRight])
			return align(irBottomRight);
		
		BOOL isAspectFit = [gravity isEqualToString:kCAGravityResizeAspect];
		BOOL isAspectFill = [gravity isEqualToString:kCAGravityResizeAspectFill];
		
		if ((!isAspectFit && !isAspectFill) || (isAspectFit && isAspectFill))
			return imageFrame;
			
		CGFloat imageSizeRatio = imageSize.width / imageSize.height;
		CGFloat imageFrameRatio = imageFrame.size.width / imageFrame.size.height;
		
		if (imageSizeRatio == imageFrameRatio)
			return imageFrame;
		
		CGSize heightFittingImageSize = (CGSize){
			CGRectGetHeight(imageFrame) * imageSizeRatio,
			CGRectGetHeight(imageFrame)
		};
		
		CGSize widthFittingImageSize = (CGSize){
			CGRectGetWidth(imageFrame),
			CGRectGetWidth(imageFrame) / imageSizeRatio
		};
		
		CGRect heightFittingImageFrame = (CGRect){
			(CGPoint) { 0.5f * (imageFrame.size.width - heightFittingImageSize.width), 0 },
			heightFittingImageSize	
		};

		CGRect widthFittingImageFrame = (CGRect){
			(CGPoint) { 0, 0.5f * (imageFrame.size.height - widthFittingImageSize.height) },
			widthFittingImageSize	
		};
		
		if (imageSizeRatio < imageFrameRatio)
			return isAspectFit ? heightFittingImageFrame : widthFittingImageFrame;
		else // imageSizeRatio > imageFrameRatio
			return isAspectFit ? widthFittingImageFrame : heightFittingImageFrame;
		
	};
	
	imageFrame = gravitize(imageFrame, imageSize, layerGravity);
	
	CGContextSaveGState(ctx);
	CGContextTranslateCTM(ctx, 0, CGRectGetHeight(layerFrame));
	CGContextScaleCTM(ctx, 1, -1);
	CGContextDrawImage(ctx, imageFrame, ownImage.CGImage);
	CGContextRestoreGState(ctx);

}

- (void) setFrame:(CGRect)newFrame {

	if (CGRectEqualToRect(newFrame, self.frame))
		return;
	
	[super setFrame:newFrame];
	
	//	Note: changing the tile size apparently does not fade
	
	if (!CGSizeEqualToSize(newFrame.size, ((CATiledLayer *)self.layer).tileSize)) {
		
		((CATiledLayer *)self.layer).tileSize = newFrame.size;
		
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
		contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		
		__block __typeof__(contentView) nrContentView = contentView;
		
		((WAImageViewTiledLayer *)self.layer).onContentsGravityChanged = ^ (NSString * newGravity) {
			((WAImageViewTiledLayer *)nrContentView.layer).contentsGravity = newGravity;
		};
		
		((WAImageViewTiledLayer *)nrContentView.layer).contentsGravity = self.layer.contentsGravity;		
		
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

- (void) setImage:(UIImage *)newImage {

	if (newImage && (newImage == self.image))
		return;
	
	[self willChangeValueForKey:@"image"];
	[image release];
	image = [newImage retain];
	[self didChangeValueForKey:@"image"];
	
	objc_setAssociatedObject(self.contentView.layer, &kWAImageView_storedImage, newImage, OBJC_ASSOCIATION_RETAIN);
	
	self.layer.contents = nil;
	[self.contentView.layer setNeedsDisplay];
	
}

@end
