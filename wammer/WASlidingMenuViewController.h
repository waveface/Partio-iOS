//
//  WASlidingMenuViewController.h
//  wammer
//
//  Created by Shen Steven on 9/16/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WASlidingMenuViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) id delegate;
@property(nonatomic) UITableViewCellSelectionStyle selectionStyle;

@end
