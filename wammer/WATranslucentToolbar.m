//
//  WATransparentToolbar.m
//  wammer
//
//  Created by Shen Steven on 4/16/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WATranslucentToolbar.h"

@implementation WATranslucentToolbar

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.translucent = YES;
    [self setBackgroundImage:[self blackTranslucentImage]
          forToolbarPosition:UIToolbarPositionAny
                  barMetrics:UIBarMetricsDefault];
  }
  return self;
}

- (UIImage *)blackTranslucentImage {
  CGRect rect = CGRectMake(0, 0, 1, 1);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5] CGColor]);
  CGContextFillRect(context, rect);
  UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return transparentImage;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
