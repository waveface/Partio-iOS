//
//  WANewSummaryDataSource.h
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WANewSummaryDataSourceDelegate <NSObject>

- (void)refreshViews;

@end

@class WANewDaySummary, WANewDayEvent;
@interface WANewSummaryDataSource : NSObject <UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) UICollectionView *summaryCollectionView;
@property (nonatomic, weak) UICollectionView *eventCollectionView;
@property (nonatomic, weak) id<WANewSummaryDataSourceDelegate> delegate;

- (id)initWithDate:(NSDate *)aDate;
- (BOOL)loadMoreDays:(NSUInteger)numOfDays since:(NSDate *)aDate;
- (NSIndexPath *)indexPathOfFirstDayEventOnDate:(NSDate *)aDate;
- (NSIndexPath *)indexPathOfLastDayEventOnDate:(NSDate *)aDate;
- (NSIndexPath *)indexPathOfDaySummaryOnDate:(NSDate *)aDate;
- (NSIndexPath *)indexPathOfDayEvent:(WANewDayEvent *)aDayEvent;
- (NSDate *)dateOfDaySummaryAtIndexPath:(NSIndexPath *)anIndexPath;
- (NSDate *)dateOfDayEventAtIndexPath:(NSIndexPath *)anIndexPath;
- (WANewDaySummary *)daySummaryAtIndexPath:(NSIndexPath *)anIndexPath;
- (WANewDayEvent *)dayEventAtIndexPath:(NSIndexPath *)anIndexPath;

@end
