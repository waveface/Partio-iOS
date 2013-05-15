//
//  WAContactPickerSectionHeaderView.m
//  wammer
//
//  Created by Shen Steven on 4/13/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioTableViewSectionHeaderView.h"

@implementation WAPartioTableViewSectionHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      self.title = [[UILabel alloc] initWithFrame:(CGRect){CGPointMake(0.f, 2.f), CGSizeMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - 2.f)}];
      [self.title setText: NSLocalizedString(@"MEMBERS_LABEL_CONTACT_PICKER", @"MEMBERS_LABEL_CONTACT_PICKER")];
      [self.title setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:14.f]];
      [self.title setTextColor:[UIColor whiteColor]];
      [self.title setTextAlignment:NSTextAlignmentCenter];
      [self.title setBackgroundColor:[UIColor clearColor]];
      [self addSubview:self.title];
      
      CALayer *topShadow = [[CALayer alloc] init];
      CGFloat shadowHeight = 2.f;
      [topShadow setMasksToBounds:NO];
      [topShadow setShadowRadius:shadowHeight];
      [topShadow setShadowOffset:CGSizeMake(0.f, 0 - shadowHeight)];
      [topShadow setShadowColor:[[UIColor blackColor] CGColor]];
      [topShadow setShadowOpacity:0.5f];
      [self.layer addSublayer:topShadow];
      
      [self.layer setMasksToBounds:NO];
      [self.layer setShadowRadius:shadowHeight];
      [self.layer setShadowOffset:CGSizeMake(0.f, shadowHeight)];
      [self.layer setShadowColor:[[UIColor blackColor] CGColor]];
      [self.layer setShadowOpacity:0.5f];

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
