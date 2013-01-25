//
//  UIImageView+WAAdditions.m
//  wammer
//
//  Created by kchiu on 13/1/25.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "UIImageView+WAAdditions.h"

@implementation UIImageView (WAAdditions)

- (void)addCrossFadeAnimationWithTargetImage:(UIImage *)image {

  CABasicAnimation *crossFade = [CABasicAnimation animationWithKeyPath:@"contents"];
  crossFade.duration = 0.3;
  crossFade.fromValue = self.image;
  crossFade.toValue = image;
  crossFade.removedOnCompletion = YES;
  [self.layer addAnimation:crossFade forKey:@"animateContents"];
  self.image = image;

}

@end
