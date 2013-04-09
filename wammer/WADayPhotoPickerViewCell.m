//
//  WADayPhotoPickerViewCell.m
//  wammer
//
//  Created by Shen Steven on 4/8/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WADayPhotoPickerViewCell.h"
@interface WADayPhotoPickerViewCell ()
@property (nonatomic, strong) CALayer *transparentLayer;
@end

@implementation WADayPhotoPickerViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {

  self.checkMarkView.hidden = YES;
  
}

- (void) setSelected:(BOOL)selected {
  [super setSelected:selected];
  
  if (selected) {
    self.checkMarkView.hidden = NO;
    self.checkMarkView.image = [UIImage imageNamed:@"IRAQ-Checkmark"];
    
    if (!self.transparentLayer) {
      self.transparentLayer = [CALayer layer];
      self.transparentLayer.opacity = 0.5;
      self.transparentLayer.opaque = NO;
      self.transparentLayer.backgroundColor = [UIColor whiteColor].CGColor;
      self.transparentLayer.frame = (CGRect){CGPointZero, self.imageView.frame.size};

      [self.imageView.layer addSublayer:self.transparentLayer];
    }

  } else {
    self.checkMarkView.hidden = YES;
    self.checkMarkView.image = nil;
    [self.transparentLayer removeFromSuperlayer];
    self.transparentLayer = nil;
  }
}


@end
