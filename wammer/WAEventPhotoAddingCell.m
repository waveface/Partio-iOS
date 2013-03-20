//
//  WAEventPhotoAddingCell.m
//  wammer
//
//  Created by Shen Steven on 3/20/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAEventPhotoAddingCell.h"

@implementation WAEventPhotoAddingCell

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.contentView.frame = CGRectInset(self.contentView.frame, 5, 5);
    self.contentView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
    self.backgroundColor = [UIColor whiteColor]; // create a white frame outside the image
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(self.contentView.frame, 20, 20)];
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];
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
