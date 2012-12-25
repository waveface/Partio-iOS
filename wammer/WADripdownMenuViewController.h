//
//  WADripdownMenuViewController.h
//  wammer
//
//  Created by Shen Steven on 10/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "WASlidingMenuViewController.h"

@protocol WADripdownMenuDelegate <NSObject>

@required
- (void) dripdownMenuItemDidSelect:(WADayViewSupportedStyle)itemStyle;

@end

typedef void (^WADripdownMenuCompletionBlock)(void);

@interface WADripdownMenuViewController : UIViewController 

@property (nonatomic, weak) id delegate;

- (void) presentDDMenuInViewController:(UIViewController*)viewController;
- (void) dismissDDMenu;
- (id) initForViewStyle:(WADayViewSupportedStyle)style completion:(WADripdownMenuCompletionBlock)completion;

@end
