//
//  WANewSummaryDataSource.h
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WANewSummaryDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, weak) UICollectionView *summaryCollectionView;
@property (nonatomic, weak) UICollectionView *eventCollectionView;

@end
