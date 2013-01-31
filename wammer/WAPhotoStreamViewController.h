//
//  WAPhotoStreamViewController.h
//  wammer
//
//  Created by jamie on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"

@interface WAPhotoStreamViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, weak) id delegate;

+ (NSFetchRequest *)fetchRequestForPhotosOnDate:(NSDate *)date;

- (id) initWithDate:(NSDate *) aDate;

@end
