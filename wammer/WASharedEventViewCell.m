//
//  WASharedEventViewCell.m
//  wammer
//
//  Created by Greener Chen on 13/4/11.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASharedEventViewCell.h"

@implementation WASharedEventViewCell

- (void)awakeFromNib
{
  static CAGradientLayer *gradientLayer;
  gradientLayer = [CAGradientLayer layer];
  [gradientLayer setBounds:CGRectMake(0, self.infoView.bounds.size.height - 80, 320, 80)];
  [gradientLayer setColors:@[(id)[[UIColor colorWithWhite:0.f alpha:0.f] CGColor],
                             (id)[[UIColor colorWithWhite:0.f alpha:0.8f] CGColor]]];
  [self.infoView.layer insertSublayer:gradientLayer atIndex:0];
  
  [self.photoNumber setFont:[UIFont fontWithName:@"OpenSans-Regular" size:12.f]];
  [self.checkinNumber setFont:[UIFont fontWithName:@"OpenSans-Regular" size:12.f]];
  [self.date setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:24.f]];
  [self.location setFont:[UIFont fontWithName:@"OpenSans-Regular" size:18.f]];
  [self.peopleNumber setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:24.f]];

}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {

  }
  return self;
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
