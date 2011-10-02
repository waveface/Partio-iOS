//
//  WAImageView.m
//  wammer
//
//  Created by Evadne Wu on 9/30/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAImageView.h"
#import <QuartzCore/QuartzCore.h> 
#import "UIImage+IRAdditions.h"

@implementation WAImageView

- (void) setImage:(UIImage *)newImage {

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		UIImage *decodedImage = [newImage irDecodedImage];
		dispatch_async(dispatch_get_main_queue(), ^ {
			[super setImage:decodedImage];
		});
	});
	
}

@end
