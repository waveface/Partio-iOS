//
//  WADripdownMenuViewController.h
//  wammer
//
//  Created by Shen Steven on 10/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "WASlidingMenuViewController.h"

@protocol WAContextMenuDelegate <NSObject>

@required
- (void) contextMenuItemDidSelect:(WADayViewSupportedStyle)itemStyle;

@end

typedef void (^WAContextMenuCompletionBlock)(void);

@interface WAContextMenuViewController : UIViewController 

@property (nonatomic, weak) id delegate;

- (void) presentContextMenuInViewController:(UIViewController*)viewController;
- (void) dismissContextMenu;
- (id) initForViewStyle:(WADayViewSupportedStyle)style completion:(WAContextMenuCompletionBlock)completion;

+ (UIView *) titleViewForContextMenu:(WADayViewSupportedStyle)style performSelector:(SEL)action withObject:(id)target;

@end
