//
//  WANewSummaryDataSource.h
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WANewDaySummary, WANewDayEvent;
@interface WANewSummaryDataSource : NSObject <UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) UICollectionView *summaryCollectionView;
@property (nonatomic, weak) UICollectionView *eventCollectionView;

- (id)initWithDate:(NSDate *)aDate;
- (BOOL)loadMoreDays:(NSUInteger)numOfDays since:(NSDate *)aDate;
- (NSIndexPath *)indexPathOfFirstDayEventOfDate:(NSDate *)aDate;
- (NSIndexPath *)indexPathOfLastDayEventOfDate:(NSDate *)aDate;
- (NSIndexPath *)indexPathOfDaySummaryOfDate:(NSDate *)aDate;
- (NSDate *)dateOfDaySummaryAtIndex:(NSUInteger)anIndex;
- (NSDate *)dateOfDayEventAtIndex:(NSUInteger)anIndex;
- (WANewDaySummary *)daySummaryAtIndex:(NSUInteger)anIndex;
- (WANewDayEvent *)dayEventAtIndex:(NSUInteger)anIndex;

@end
