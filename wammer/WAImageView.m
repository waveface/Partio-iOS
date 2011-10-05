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


static NSString * const kWAImageView_storedImage = @"kWAImageView_storedImage";


@interface WAImageViewTiledLayer : CATiledLayer

@end

@implementation WAImageViewTiledLayer

+ (NSTimeInterval) fadeDuration {

	return 0.0f;

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
	
	CGContextDrawImage(ctx, layer.frame, ownImage.CGImage);

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

	NSLog(@"%@, image %@ -> %@", self, self.image, newImage);

	if (newImage == self.image)
		return;
		
	[super setImage:newImage];
	
	self.layer.contents = nil;
	[self.layer setNeedsDisplay];
	
	objc_setAssociatedObject(self.layer, &kWAImageView_storedImage, newImage, OBJC_ASSOCIATION_RETAIN);

}

@end
