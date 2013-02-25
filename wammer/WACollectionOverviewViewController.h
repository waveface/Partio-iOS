//
//  WACollectionOverviewViewController.h
//  wammer
//
//  Created by jamie on 13/2/21.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WACollection;
@interface WACollectionOverviewViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) WACollection *collection;

@end
