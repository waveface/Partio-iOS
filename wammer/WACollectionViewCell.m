//
//  WACollectionViewCell.m
//  wammer
//
//  Created by jamie on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACollectionViewCell.h"
#import <ColorArt/SLColorArt.h>

NSString *const kCollectionViewCellID = @"WACollectionViewCell";

@implementation WACollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
	 NSArray *arrayOfView = [[NSBundle mainBundle] loadNibNamed:@"WACollectionViewCell" owner:self options:nil];
	 self = [arrayOfView objectAtIndex:0];
	 self.layer.cornerRadius = 10.0f;
	 self.layer.backgroundColor = [UIColor whiteColor].CGColor;
	 self.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:1.0f].CGColor;
	 self.layer.borderWidth = 1.0f;
	 self.coverImage.layer.cornerRadius = 4.0f;
	 CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
	 gradientLayer.frame = _title.frame;
	 gradientLayer.colors = @[(id)[[[UIColor blackColor] colorWithAlphaComponent:0.0f] CGColor],
									(id)[[[UIColor blackColor] colorWithAlphaComponent:0.8f] CGColor]];
	 [_coverImage.layer addSublayer:gradientLayer];
  }
  return self;
}

- (void)setImage:(UIImage *)image {
  if (image) {
	 SLColorArt *colorArt = [[SLColorArt alloc] initWithImage:image scaledSize:_coverImage.frame.size];
	 _coverImage.image = colorArt.scaledImage;
	 _title.textColor = colorArt.primaryColor;
  }
}

- (void) prepareForReuse {
  if (self.cover) {
    [self.cover irRemoveAllObserves];
    self.cover = nil;
  }
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
