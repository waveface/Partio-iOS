//
//  WATransparentToolbar.m
//  wammer
//
//  Created by Greener Chen on 13/4/19.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WATransparentToolbar.h"

@implementation WATransparentToolbar

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    //self.translucent = YES;
    [self setBackgroundImage:[self clearColorImage]
          forToolbarPosition:UIToolbarPositionAny
                  barMetrics:UIBarMetricsDefault];
  }
  return self;
}

- (UIImage *)clearColorImage {
  CGRect rect = CGRectMake(0, 0, 1, 1);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:1.f alpha:0.f] CGColor]);
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
