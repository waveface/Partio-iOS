//
//  WAPhotoGalleryCell.m
//  wammer
//
//  Created by Shen Steven on 4/30/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoGalleryCell.h"

@implementation WAPhotoGalleryCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
  self.imageView.layer.cornerRadius = 5.0f;
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
