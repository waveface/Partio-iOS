//
//  WANewSummaryDataSource.m
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewSummaryDataSource.h"

@interface WANewSummaryDataSource ()

@property (nonatomic, strong) NSArray *daySummaries;
@property (nonatomic, strong) NSArray *dayEvents;

@end

@implementation WANewSummaryDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

  if (collectionView == self.summaryCollectionView) {
    return [self.daySummaries count];
  } else if (collectionView == self.eventCollectionView) {
    return [self.dayEvents count];
  } else {
    NSAssert(NO, @"unexpected collection view %@", collectionView);
    return 0;
  }

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
}

@end
