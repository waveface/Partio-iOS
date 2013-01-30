//
//  WAEventDescriptionView.m
//  wammer
//
//  Created by kchiu on 13/1/30.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAEventDescriptionView.h"

@implementation WAEventDescriptionView

+ (WAEventDescriptionView *)viewFromNib {
  
  WAEventDescriptionView *view = [[[UINib nibWithNibName:@"WAEventDescriptionView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
  
  return view;
}

- (void)awakeFromNib {
  
  CAGradientLayer *gradient = [CAGradientLayer layer];
  gradient.frame = (CGRect) {CGPointZero, self.frame.size};
  gradient.colors = @[(id)[[UIColor colorWithWhite:0.0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0.0 alpha:0.8] CGColor]];
  [self.layer insertSublayer:gradient atIndex:0];
  
}

@end
