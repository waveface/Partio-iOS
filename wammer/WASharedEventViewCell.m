//
//  WASharedEventViewCell.m
//  wammer
//
//  Created by Greener Chen on 13/4/11.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASharedEventViewCell.h"

@implementation WASharedEventViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
      _photoNumber = [[UILabel alloc] init];
      _checkinNumber = [[UILabel alloc] init];
      _date = [[UILabel alloc] init];
      _peopleNumber = [[UILabel alloc] init];
      
      [_photoNumber setFont:[UIFont fontWithName:@"Regular" size:24.f]];
      [_photoNumber setTextColor:[UIColor whiteColor]];
      [_checkinNumber setFont:[UIFont fontWithName:@"Regular" size:24.f]];
      [_checkinNumber setTextColor:[UIColor whiteColor]];
      [_date setFont:[UIFont fontWithName:@"Semibold" size:36.f]];
      [_date setTextColor:[UIColor whiteColor]];
      [_peopleNumber setFont:[UIFont fontWithName:@"Regular" size:36.f]];
      [_peopleNumber setTextColor:[UIColor whiteColor]];
      
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
