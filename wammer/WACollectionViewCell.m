//
//  WACollectionViewCell.m
//  wammer
//
//  Created by jamie on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACollectionViewCell.h"

NSString *const kCollectionViewCellID = @"WACollectionViewCell";

@implementation WACollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
			NSArray *arrayOfView = [[NSBundle mainBundle] loadNibNamed:@"WACollectionViewCell" owner:self options:nil];
			self = [arrayOfView objectAtIndex:0];
			self.backgroundImageView.layer.cornerRadius = 10.0f;
			self.backgroundImageView.layer.backgroundColor = [UIColor whiteColor].CGColor;
			self.backgroundImageView.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:1.0f].CGColor;
			self.backgroundImageView.layer.borderWidth = 1.0f;
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
