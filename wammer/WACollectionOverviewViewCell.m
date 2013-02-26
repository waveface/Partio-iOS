//
//  WACollectionOverviewViewCell.m
//  wammer
//
//  Created by jamie on 13/2/26.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WACollectionOverviewViewCell.h"

@implementation WACollectionOverviewViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"WACollectionOverviewViewCell" owner:self options:nil];
      self = [views objectAtIndex:0];
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
