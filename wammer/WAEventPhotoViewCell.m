//
//  WAEventPhotoViewCell.m
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventPhotoViewCell.h"

@implementation WAEventPhotoViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
			
			self.imageView = [[UIImageView alloc] initWithFrame:(CGRect){CGPointZero, frame.size}];
			self.imageView.backgroundColor = [UIColor lightGrayColor];
			self.imageView.contentMode = UIViewContentModeScaleAspectFill;
			self.imageView.clipsToBounds = YES;
			[self addSubview:self.imageView];
			
			self.checkMarkView = [[UIImageView alloc] initWithFrame:(CGRect) {{5, 5}, {32, 32}}];
			self.checkMarkView.backgroundColor = [UIColor clearColor];
			self.checkMarkView.clipsToBounds = YES;
			self.checkMarkView.image = nil;
			[self addSubview:self.checkMarkView];
			[self bringSubviewToFront:self.checkMarkView];

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
