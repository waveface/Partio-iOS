//
//  WASlidingMenuViewController.h
//  wammer
//
//  Created by Shen Steven on 9/16/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"
#import "WADayViewController.h"
#import "WAStatusBar.h"


@interface WASlidingMenuViewController : UITableViewController <IIViewDeckControllerDelegate>

@property (nonatomic, weak) id delegate;
@property (nonatomic, readonly, strong) WAStatusBar *statusBar;

+ (UIViewController *)dayViewControllerForViewStyle:(WADayViewSupportedStyle)viewStyle ;

- (void) switchToViewStyle:(WADayViewSupportedStyle)viewStyle;
- (void) switchToViewStyle:(WADayViewSupportedStyle)viewStyle onDate:(NSDate*)date;
- (void) switchToViewStyle:(WADayViewSupportedStyle)viewStyle onDate:(NSDate*)date animated:(BOOL)animated;

@end
