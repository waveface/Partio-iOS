//
//  WAPhotoStreamViewController.h
//  wammer
//
//  Created by jamie on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WADayViewController.h"
#import "IIViewDeckController.h"

@interface WAPhotoStreamViewController : UIViewController <WADayViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id delegate;

+ (NSFetchRequest *)fetchRequestForPhotosOnDate:(NSDate *)date;

- (void)viewControllerInitialAppeareadOnDayView;
- (id) initWithDate:(NSDate *) aDate;

@end
