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

@end

@implementation WAImageViewTiledLayer

+ (NSTimeInterval) fadeDuration {

	return 0.25f;

}

@end


@implementation WAImageView

+ (Class) layerClass {

	return [WAImageViewTiledLayer class];

}

- (void) drawRect:(CGRect)rect {

	//	NO OP

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
	
	((CATiledLayer *)self.layer).tileSize = newFrame.size;
	
	self.layer.contents = nil;
	[self.layer setNeedsDisplay];
	
}

- (void) setImage:(UIImage *)newImage {

	if (newImage == self.image)
		return;
		
	[super setImage:newImage];
	
	self.layer.contents = nil;
	[self.layer setNeedsDisplay];
	
	objc_setAssociatedObject(self.layer, &kWAImageView_storedImage, newImage, OBJC_ASSOCIATION_RETAIN);

}

@end
