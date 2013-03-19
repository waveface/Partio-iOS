//
//  WAEventPhotoViewCell.m
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventPhotoViewCell.h"

@interface WAEventPhotoViewCell ()
@property (nonatomic, strong) CALayer *transparentLayer;
@end

@implementation WAEventPhotoViewCell {
  BOOL _editing;
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    
    self.imageView = [[UIImageView alloc] initWithFrame:(CGRect){CGPointZero, frame.size}];
    self.imageView.backgroundColor = [UIColor lightGrayColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];
    
    self.checkMarkView = [[UIImageView alloc] initWithFrame:(CGRect) {{5, 5}, {32, 32}}];
    self.checkMarkView.backgroundColor = [UIColor clearColor];
    self.checkMarkView.clipsToBounds = YES;
    self.checkMarkView.image = nil;
    [self.contentView addSubview:self.checkMarkView];
    [self.contentView bringSubviewToFront:self.checkMarkView];
    
    _editing = NO;
    
  }
  return self;
}

- (void) setEditing:(BOOL)editing {
  if (!_editing && editing) {
    self.transparentLayer = [CALayer layer];
    self.transparentLayer.opacity = 0.5;
    self.transparentLayer.opaque = NO;
    self.transparentLayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.transparentLayer.frame = (CGRect){CGPointZero, self.imageView.frame.size};
    
    [self.imageView.layer addSublayer:self.transparentLayer];
    
  }
  
  if (_editing && !editing) {
    [self.transparentLayer removeFromSuperlayer];
    self.transparentLayer = nil;
  }
  
  _editing = editing;
}

- (BOOL) isEditing {
  return _editing;
}

- (void) setSelected:(BOOL)selected {
  [super setSelected:selected];
  
  if (selected) {
    [self.transparentLayer removeFromSuperlayer];
    self.checkMarkView.hidden = NO;
    self.checkMarkView.image = [UIImage imageNamed:@"IRAQ-Checkmark"];
  } else {
    self.checkMarkView.hidden = YES;
    self.checkMarkView.image = nil;
    [self.imageView.layer addSublayer:self.transparentLayer];
  }
}

@end
