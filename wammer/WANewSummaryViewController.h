//
//  WANewSummaryViewController.h
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAContextMenuViewController.h"
#import "WADayViewController.h"
#import "WANewSummaryDataSource.h"

@interface WANewSummaryViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WAContextMenuDelegate, WADaysControlling, WANewSummaryDataSourceDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIPageControl *eventPageControl;
@property (weak, nonatomic) IBOutlet UICollectionView *summaryCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *eventCollectionView;

@end
