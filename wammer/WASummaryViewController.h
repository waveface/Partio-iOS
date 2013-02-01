//
//  WASummaryViewController.h
//  wammer
//
//  Created by kchiu on 13/1/21.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAContextMenuViewController.h"

@interface WASummaryViewController : UIViewController <UIScrollViewDelegate, WAContextMenuDelegate, WADayViewControllerDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *upperMaskView;
@property (weak, nonatomic) IBOutlet UIView *lowerMaskView;
@property (weak, nonatomic) IBOutlet UIScrollView *eventScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *summaryScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *eventPageControll;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

- (id)initWithDate:(NSDate *)date;

@end
