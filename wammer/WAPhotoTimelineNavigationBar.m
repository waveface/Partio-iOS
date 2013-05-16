//
//  WAPhotoTimelineNavigationBar.m
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoTimelineNavigationBar.h"

@implementation WAPhotoTimelineNavigationBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
  if (self.solid) {
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:(CGRect){CGPointZero, self.overlayImageSize}];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.image = self.overlayImage;
    imageView.layer.opacity = 0.9;
    imageView.layer.opaque = NO;
    CALayer *darken = [[CALayer alloc] init];
    darken.frame = imageView.frame;
    darken.opaque = NO;
    darken.opacity = 0.6;
    darken.backgroundColor = [UIColor blackColor].CGColor;
    [imageView.layer insertSublayer:darken above:imageView.layer];
    
    UIGraphicsBeginImageContext(self.overlayImageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //    UIGraphicsPushContext(context);
    [imageView.layer renderInContext:context];
    UIImage *renderingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //    UIGraphicsPopContext();
    
    if (!renderingImage) {
      NSLog(@"unable to generate rendering image for navigation bar");
      return;
    }
    
    context = UIGraphicsGetCurrentContext();
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    transform = CGAffineTransformTranslate(transform, self.overlayImageSize.width, self.overlayImageSize.height);
    transform = CGAffineTransformRotate(transform, M_PI);
    //    transform = CGAffineTransformTranslate(transform, 320, 0);
    //    transform = CGAffineTransformScale(transform, -1, 1);
    transform = CGAffineTransformTranslate(transform, self.overlayImageSize.width, 0);
    transform = CGAffineTransformScale(transform, -1, 1);
    
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, (CGRect){{0, self.overlayImageSize.height - self.frame.size.height}, self.overlayImageSize}, renderingImage.CGImage);
    
  } else {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    CGContextClearRect(context, rect);
    UIGraphicsPopContext();
  }

}

@end
