//
//  WADripdownMenuViewController.h
//  wammer
//
//  Created by Shen Steven on 10/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//


typedef void (^WADripdownMenuCompletionBlock)(void);

#import <UIKit/UIKit.h>
#import "WASlidingMenuViewController.h"

@interface WADripdownMenuViewController : UIViewController 

- (void) presentDDMenuInViewController:(UIViewController*)viewController;
- (id) initForViewStyle:(WADayViewSupportedStyle)style completion:(WADripdownMenuCompletionBlock)completion;

@end
