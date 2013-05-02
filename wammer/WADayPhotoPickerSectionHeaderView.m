//
//  WADayPhotoPickerSectionHeaderView.m
//  wammer
//
//  Created by Shen Steven on 4/8/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WADayPhotoPickerSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>

@implementation WADayPhotoPickerSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
  
  CALayer *topShadow = [[CALayer alloc] init];
  CGFloat shadowHeight = 2.f;
  [topShadow setMasksToBounds:NO];
  [topShadow setShadowRadius:shadowHeight];
  [topShadow setShadowColor:[[UIColor blackColor] CGColor]];
  [topShadow setShadowOpacity:0.4f];
  UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.layer.frame.size.width, -shadowHeight)];
  topShadow.shadowPath = path.CGPath;
  [self.layer insertSublayer:topShadow below:self.layer];
  
  [self.layer setMasksToBounds:NO];
  [self.layer setShadowRadius:shadowHeight];
  [self.layer setShadowOffset:CGSizeMake(0.f, shadowHeight)];
  [self.layer setShadowColor:[[UIColor blackColor] CGColor]];
  [self.layer setShadowOpacity:0.5f];
  
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
