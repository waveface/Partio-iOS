//
//  WASlidingMenuViewController.h
//  wammer
//
//  Created by Shen Steven on 9/16/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WASlidingMenuDelegate <NSObject>

@required
- (void) slidingMenuItemDidSelected:(id)result;

@end

@interface WASlidingMenuViewController : UITableViewController

@property (nonatomic, weak) id delegate;

@end
