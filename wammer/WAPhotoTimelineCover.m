//
//  WAPhotoTimelineCover.m
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoTimelineCover.h"
#import <QuartzCore/QuartzCore.h>

@implementation WAPhotoTimelineCover

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
  
//    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
//    gradientLayer.frame = (CGRect) {CGPointZero, self.gradientBackground.frame.size};
//    gradientLayer.colors = @[(id)[[UIColor colorWithWhite:0.0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0.0 alpha:0.8] CGColor]];
//    
//    [self.gradientBackground.layer insertSublayer:gradientLayer above:nil];
  
    self.mapView.layer.borderWidth = 4;
    self.mapView.layer.borderColor = [UIColor blackColor].CGColor;
    self.mapView.layer.cornerRadius = 30;
    self.mapView.layer.masksToBounds = YES;
  
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
