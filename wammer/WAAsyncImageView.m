//
//  WAAsyncImageView.m
//  wammer
//
//  Created by Evadne Wu on 12/13/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAAsyncImageView.h"
#import "UIImage+IRAdditions.h"


@interface WAAsyncImageView ()

@property (nonatomic, readwrite, assign) void * lastImagePtr;

- (void) primitiveSetImage:(UIImage *)image;

@end

@implementation WAAsyncImageView
@synthesize lastImagePtr;
@dynamic delegate;

- (void) setImage:(UIImage *)newImage {

	[self setImage:newImage withOptions:WAImageViewForceAsynchronousOption];

}

- (void) setImage:(UIImage *)newImage withOptions:(WAImageViewOptions)options {

	void * imagePtr = (__bridge void *)newImage;

	if (lastImagePtr == imagePtr)
		return;
  
  lastImagePtr = imagePtr;
	
  if (!newImage) {
	
		[self primitiveSetImage:nil];
    return;
		
  }

	if (options & WAImageViewForceSynchronousOption) {
	
		[self primitiveSetImage:newImage];
		[self.delegate imageViewDidUpdate:self];
		
		return;
		
	}
	
	BOOL shouldEmptyContents = ![self.image.irRepresentedObject isEqual:newImage.irRepresentedObject];
	if (shouldEmptyContents) {
		
		[self primitiveSetImage:nil];
		
	}
	
	__weak WAAsyncImageView *wSelf = self;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^ {

		if (!wSelf)
			return;

		if (wSelf.lastImagePtr != imagePtr)
			return;
		
		UIImage *decodedImage = [newImage irDecodedImage];

		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if (!wSelf)
				return;
			
			if (wSelf.lastImagePtr != imagePtr)
				return;
			
			[wSelf primitiveSetImage:decodedImage];
			[wSelf.delegate imageViewDidUpdate:wSelf];
		
		});

	});

}

- (void) primitiveSetImage:(UIImage *)image {

	[super setImage:image];

}

@end
