//
//  WASwipeableTableViewController.h
//  wammer
//
//  Created by Shen Steven on 10/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRTableViewController.h"

@interface WASwipeableTableViewController : IRTableViewController

@property (nonatomic, readwrite, strong) IRTableView *tableView;

- (void) pushTableViewToLeftWithDuration:(float)duration completion:(void(^)(void))completionBlock;
- (void) pullTableViewFromRightWithDuration:(float)duration completion:(void(^)(void))completionBlock;

- (void) handleSwipeRight:(UISwipeGestureRecognizer*)swipe;
- (void) handleSwipeLeft:(UISwipeGestureRecognizer*)swipe;

- (IRTableView *) tableViewLeft;
- (IRTableView *) tableViewRight;

@end
