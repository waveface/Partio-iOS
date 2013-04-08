//
//  WAPhotoGroupViewCell.m
//  wammer
//
//  Created by Shen Steven on 4/4/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoHighlightViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation WAPhotoHighlightViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) awakeFromNib {
  
  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.frame = (CGRect) {CGPointZero, self.bgImageView.frame.size};
  gradientLayer.colors = @[(id)[[UIColor colorWithWhite:0.0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0.0 alpha:0.8] CGColor]];
  
  [self.bgImageView.layer insertSublayer:gradientLayer above:nil];

}

@end
