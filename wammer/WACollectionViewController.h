//
//  WACollectionViewController.h
//  wammer
//
//  Created by jamie on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"

@interface WACollectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, IIViewDeckControllerDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end
