
//
//  WADocumentStreamViewController.h
//  wammer
//
//  Created by kchiu on 12/12/5.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WADayViewController.h"
#import "WAFile.h"

@interface WADocumentStreamViewController : UIViewController <WADayViewController, UICollectionViewDelegate, UICollectionViewDataSource,  NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

+ (NSFetchRequest *)fetchRequestForFileAccessLogsOnDate:(NSDate *)date;
- (id)initWithDate:(NSDate *)date;
- (void)viewControllerInitialAppeareadOnDayView;

@end
