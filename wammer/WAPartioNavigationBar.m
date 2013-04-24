//
//  WAPartioNavigationBar.m
//  wammer
//
//  Created by Shen Steven on 4/19/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioNavigationBar.h"

@implementation WAPartioNavigationBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
  [self.layer setMasksToBounds:NO];
  [self.layer setShadowRadius:2.f];
  [self.layer setShadowOffset:CGSizeMake(0.f, 2.f)];
  [self.layer setShadowColor:[[UIColor blackColor] CGColor]];
  [self.layer setShadowOpacity:0.5f];
  
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);

  CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.168 green:0.168 blue:0.168 alpha:1].CGColor);
  CGContextFillRect(context, rect);

  CGContextRestoreGState(context);
  
}


@end
