//
//  WAPhotoStreamViewCell.m
//  wammer
//
//  Created by jamie on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAPhotoStreamViewCell.h"

NSString * const kPhotoStreamCellID = @"PhotoStreamViewCell";

@implementation WAPhotoStreamViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
			NSArray *arrayOfView = [[NSBundle mainBundle] loadNibNamed:@"WAPhotoStreamViewCell" owner:self options:nil];
			self = [arrayOfView objectAtIndex:0];
			
			self.backgroundColor = [UIColor redColor];
			self.imageView.backgroundColor = [UIColor darkTextColor];
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
