//
//  WAAyncImageView.m
//  wammer
//
//  Created by Evadne Wu on 12/13/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAAyncImageView.h"
#import "UIImage+IRAdditions.h"

@implementation WAAyncImageView

- (void) setImage:(UIImage *)image {

  if (self.image == image)
    return;

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^ {

    UIImage *decodedImage = [image irDecodedImage];
    dispatch_async(dispatch_get_main_queue(), ^{
    
      if (self.image != decodedImage)
        return;
    
      [super setImage:decodedImage];
      [self.delegate imageViewDidUpdate:self];
      
    });
  
  });

}

@end
