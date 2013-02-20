//
//  UIViewController+WAAdditions.m
//  wammer
//
//  Created by Shen Steven on 2/20/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "UIViewController+WAAdditions.h"

@implementation UIViewController (WAAdditions)
- (void) zapModal {
 
  if (self.presentedViewController) {
    NSLog(@"%@", [self.presentedViewController description]);
    [self.presentedViewController zapModal];
  }
  
  [self dismissViewControllerAnimated:NO completion:nil];
  
}
@end
