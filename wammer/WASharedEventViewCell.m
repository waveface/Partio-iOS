//
//  WASharedEventViewCell.m
//  wammer
//
//  Created by Greener Chen on 13/4/11.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASharedEventViewCell.h"

@implementation WASharedEventViewCell

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
   
    [self.photoNumber setFont:[UIFont fontWithName:@"OpenSans_Regular" size:12.f]];
    [self.checkinNumber setFont:[UIFont fontWithName:@"OpenSans_Regular" size:12.f]];
    [self.date setFont:[UIFont fontWithName:@"OpenSans_Semibold" size:24.f]];
    [self.location setFont:[UIFont fontWithName:@"OpenSans_Regular" size:18.f]];
    [self.peopleNumber setFont:[UIFont fontWithName:@"OpenSans_Semibold" size:24.f]];
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
