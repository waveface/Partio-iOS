//
//  WANewSummaryDataSource.m
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewSummaryDataSource.h"
#import "WANewDaySummary.h"
#import "WANewDayEvent.h"
#import "WANewDaySummaryViewCell.h"
#import "WANewDayEventViewCell.h"
#import "NSDate+WAAdditions.h"
#import "WADataStore.h"
#import "WAArticle.h"

@interface WANewSummaryDataSource ()

@property (nonatomic, strong) NSDate *firstDate;
@property (nonatomic, strong) NSDate *lastDate;
@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, strong) NSMutableArray *daySummaries;
@property (nonatomic, strong) NSMutableArray *dayEvents;
@property (nonatomic, strong) WANewDayEvent *currentDayEvent;

@property (nonatomic, strong) NSFetchedResultsController *articleFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *photoFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *documentFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *webpageFetchedResultsController;

@end

@implementation WANewSummaryDataSource

- (id)initWithDate:(NSDate *)aDate {

  self = [super init];
  if (self) {
    self.daySummaries = [NSMutableArray array];
    self.dayEvents = [NSMutableArray array];
    self.firstDate = aDate;
    self.lastDate = aDate;
    self.currentDate = aDate;
    [self loadMoreDays:20 since:self.firstDate];
  }
  return self;

}

- (void)loadMoreDays:(NSUInteger)numOfDays since:(NSDate *)aDate {
  
  if (![self.daySummaries count]) {
    WANewDaySummary *daySummary = [[WANewDaySummary alloc] init];
    daySummary.date = aDate;
    [daySummary reloadData];
    [self.daySummaries addObject:daySummary];
  }

  if ([aDate isEqualToDate:self.firstDate]) {
    for (NSInteger i = 1; i <= numOfDays; i++) {
      WANewDaySummary *daySummary = [[WANewDaySummary alloc] init];
      daySummary.date = [self.firstDate dateOfPreviousNumOfDays:i];
      [daySummary reloadData];
      [self.daySummaries insertObject:daySummary atIndex:0];
    }
    self.firstDate = [self.daySummaries[0] date];
  } else if ([aDate isEqualToDate:self.lastDate]) {
    for (NSInteger i = 1; i <= numOfDays; i++) {
      WANewDaySummary *daySummary = [[WANewDaySummary alloc] init];
      daySummary.date = [self.lastDate dateOfNextNumOfDays:i];
      [daySummary reloadData];
      [self.daySummaries addObject:daySummary];
    }
    self.lastDate = [[self.daySummaries lastObject] date];
  }
  
  [self resetFetchedResultsControllers];

}

- (void)resetFetchedResultsControllers {

  NSManagedObjectContext *moc = [[WADataStore defaultStore] defaultAutoUpdatedMOC];

  if (!self.articleFetchedResultsController) {
    NSFetchRequest *articleFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAArticle"];
    [articleFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"eventStartDate" ascending:YES]]];
    self.articleFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:articleFetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    self.articleFetchedResultsController.delegate = self;
  }
  [self.articleFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"hidden = FALSE AND event = TRUE AND eventStartDate >= %@ AND eventStartDate <= %@", self.firstDate, [self.lastDate dayEnd]]];
  [self.articleFetchedResultsController performFetch:nil];
  NSArray *articles = self.articleFetchedResultsController.fetchedObjects;

  if ([self.dayEvents count]) {
    // load more days
    NSDate *firstDayEventDate = [[self.dayEvents[0] startTime] dayBegin];
    NSDate *lastDayEventDate = [[[self.dayEvents lastObject] startTime] dayBegin];
    NSMutableArray *earlierArticles = [NSMutableArray array];
    NSMutableArray *laterArticles = [NSMutableArray array];
    for (WAArticle *article in articles) {
      if ([article.eventStartDate compare:firstDayEventDate] == NSOrderedAscending) {
        [earlierArticles addObject:article];
      } else if ([article.eventStartDate compare:lastDayEventDate] == NSOrderedDescending) {
        [laterArticles addObject:article];
      }
    }
    
    if (!isSameDay(self.firstDate, firstDayEventDate)) {
      NSUInteger numOfArticles = [earlierArticles count];
      NSUInteger articleIndex = 0;
      NSDate *firstPreviousDay = [self.firstDate dateOfPreviousDay];
      for (NSDate *date = [firstDayEventDate dateOfPreviousDay]; !isSameDay(date, firstPreviousDay); date = [date dateOfPreviousDay]) {
        BOOL hasArticles = NO;
        while (articleIndex < numOfArticles) {
          WAArticle *article = earlierArticles[numOfArticles - articleIndex - 1];
          if (isSameDay(date,  article.eventStartDate)) {
            hasArticles = YES;
            WANewDayEvent *dayEvent = [[WANewDayEvent alloc] initWithArticle:article date:date];
            [self.dayEvents insertObject:dayEvent atIndex:0];
            articleIndex++;
          } else {
            break;
          }
        }
        if (!hasArticles) {
          WANewDayEvent *dayEvent = [[WANewDayEvent alloc] initWithArticle:nil date:date];
          [self.dayEvents insertObject:dayEvent atIndex:0];
        }
      }
    }
    
    if (!isSameDay(self.lastDate, lastDayEventDate)) {
      NSUInteger numOfArticles = [laterArticles count];
      NSUInteger articleIndex = 0;
      NSDate *lastFollowingDay = [self.lastDate dateOfFollowingDay];
      for (NSDate *date = [lastDayEventDate dateOfFollowingDay]; !isSameDay(date, lastFollowingDay); date = [date dateOfFollowingDay]) {
        BOOL hasArticles = NO;
        while (articleIndex < numOfArticles) {
          WAArticle *article = laterArticles[articleIndex];
          if (isSameDay(date,  article.eventStartDate)) {
            hasArticles = YES;
            WANewDayEvent *dayEvent = [[WANewDayEvent alloc] initWithArticle:article date:date];
            [self.dayEvents addObject:dayEvent];
            articleIndex++;
          } else {
            break;
          }
        }
        if (!hasArticles) {
          WANewDayEvent *dayEvent = [[WANewDayEvent alloc] initWithArticle:nil date:date];
          [self.dayEvents addObject:dayEvent];
        }
      }
    }
  } else {
    // initilaization
    NSUInteger numOfArticles = [articles count];
    NSUInteger articleIndex = 0;
    NSDate *lastFollowingDay = [self.lastDate dateOfFollowingDay];
    for (NSDate *date = self.firstDate; !isSameDay(date, lastFollowingDay); date = [date dateOfFollowingDay]) {
      BOOL hasArticles = NO;
      while (articleIndex < numOfArticles) {
        WAArticle *article = articles[articleIndex];
        if (isSameDay(date, article.eventStartDate)) {
          hasArticles = YES;
          WANewDayEvent *dayEvent = [[WANewDayEvent alloc] initWithArticle:article date:date];
          [self.dayEvents addObject:dayEvent];
          articleIndex++;
        } else {
          break;
        }
      }
      if (!hasArticles) {
        WANewDayEvent *dayEvent = [[WANewDayEvent alloc] initWithArticle:nil date:date];
        [self.dayEvents addObject:dayEvent];
      }
    }
  }
  
  if (!self.photoFetchedResultsController) {
    NSFetchRequest *photosFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAFile"];
    [photosFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
    self.photoFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:photosFetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    self.photoFetchedResultsController.delegate = self;
  }
  [self.photoFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"photoDay.day >= %@ AND photoDay.day <= %@", self.firstDate, self.lastDate]];
  [self.photoFetchedResultsController performFetch:nil];
  
  if (!self.documentFetchedResultsController) {
    NSFetchRequest *documentsFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAFileAccessLog"];
    [documentsFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"accessTime" ascending:NO]]];
    self.documentFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:documentsFetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    self.documentFetchedResultsController.delegate = self;
  }
  [self.documentFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"day.day >= %@ AND day.day <= %@", self.firstDate, self.lastDate]];
  [self.documentFetchedResultsController performFetch:nil];
  
  if (!self.webpageFetchedResultsController) {
    NSFetchRequest *webpagesFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAFileAccessLog"];
    [webpagesFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"accessTime" ascending:NO]]];
    self.webpageFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:webpagesFetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    self.webpageFetchedResultsController.delegate = self;
  }
  [self.webpageFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"dayWebpages.day >= %@ AND dayWebpages.day <= %@", self.firstDate, self.lastDate]];
  [self.webpageFetchedResultsController performFetch:nil];
  
}

- (void)setSummaryCollectionView:(UICollectionView *)summaryCollectionView {

  _summaryCollectionView = summaryCollectionView;
  
  [_summaryCollectionView registerNib:[UINib nibWithNibName:@"WANewDaySummaryViewCell" bundle:nil] forCellWithReuseIdentifier:kWANewDaySummaryViewCellID];

}

- (void)setEventCollectionView:(UICollectionView *)eventCollectionView {

  _eventCollectionView = eventCollectionView;
  
  [_eventCollectionView registerNib:[UINib nibWithNibName:@"WANewDayEventViewCell" bundle:nil] forCellWithReuseIdentifier:kWANewDayEventViewCellID];

}

- (NSIndexPath *)indexPathOfDaySummaryOfDate:(NSDate *)aDate {

  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSUInteger flags = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSTimeZoneCalendarUnit;
  NSDateComponents *dateComponents = [calendar components:flags fromDate:self.firstDate toDate:aDate options:0];
  NSInteger itemIndex = dateComponents.day;

  return [NSIndexPath indexPathForItem:([self.daySummaries count]-itemIndex-1) inSection:0];

}

- (NSIndexPath *)indexPathOfFirstDayEventOfDate:(NSDate *)aDate {

  NSIndexSet *indexes = [self.dayEvents indexesOfObjectsPassingTest:^BOOL(WANewDayEvent *dayEvent, NSUInteger idx, BOOL *stop) {
    return isSameDay(dayEvent.startTime, aDate);
  }];
  
  NSUInteger itemIndex = [indexes lastIndex];
  NSAssert(itemIndex != NSNotFound, @"There should be a day event for any searchable dates");

  return [NSIndexPath indexPathForItem:([self.dayEvents count]-itemIndex-1) inSection:0];

}

- (NSIndexPath *)indexPathOfLastDayEventOfDate:(NSDate *)aDate {

  NSIndexSet *indexes = [self.dayEvents indexesOfObjectsPassingTest:^BOOL(WANewDayEvent *dayEvent, NSUInteger idx, BOOL *stop) {
    return isSameDay(dayEvent.startTime, aDate);
  }];
  
  NSUInteger itemIndex = [indexes firstIndex];
  NSAssert(itemIndex != NSNotFound, @"There should be a day event for any searchable dates");
  
  return [NSIndexPath indexPathForItem:([self.dayEvents count]-itemIndex-1) inSection:0];

}

- (NSDate *)dateOfDaySummaryAtIndex:(NSUInteger)anIndex {

  NSUInteger itemIndex = ([self.daySummaries count]-anIndex-1);
  WANewDaySummary *daySummary = self.daySummaries[itemIndex];
  return daySummary.date;

}

- (NSDate *)dateOfDayEventAtIndex:(NSUInteger)anIndex {

  NSUInteger itemIndex = ([self.dayEvents count]-anIndex-1);
  WANewDayEvent *dayEvent = self.dayEvents[itemIndex];
  return [dayEvent.startTime dayBegin];

}

- (id)daySummaryAtIndex:(NSUInteger)anIndex {

  NSUInteger itemIndex = ([self.daySummaries count]-anIndex-1);
  WANewDaySummary *daySummary = self.daySummaries[itemIndex];
  return daySummary;

}

- (WANewDayEvent *)dayEventAtIndex:(NSUInteger)anIndex {

  NSUInteger itemIndex = ([self.dayEvents count]-anIndex-1);
  WANewDayEvent *dayEvent = self.dayEvents[itemIndex];
  return dayEvent;

}

- (NSArray *)indexesOfDaySummariesFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
  
  NSIndexPath *firstIndexPath = [self indexPathOfDaySummaryOfDate:fromDate];
  NSIndexPath *lastIndexPath = [self indexPathOfDaySummaryOfDate:toDate];
  NSAssert(firstIndexPath.section == lastIndexPath.section, @"All index paths are refering to section 0");
  NSMutableArray *indexes = [NSMutableArray array];
  for (NSInteger i = firstIndexPath.item; i <= lastIndexPath.item; i++) {
    [indexes addObject:[NSIndexPath indexPathForItem:i inSection:0]];
  }
  return indexes;

}

- (NSArray *)indexesOfDayEventsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {

  NSIndexPath *firstIndexPath = [self indexPathOfFirstDayEventOfDate:fromDate];
  NSIndexPath *lastIndexPath = [self indexPathOfLastDayEventOfDate:toDate];
  NSAssert(firstIndexPath.section == lastIndexPath.section, @"All index paths are refering to section 0");
  NSMutableArray *indexes = [NSMutableArray array];
  for (NSInteger i = firstIndexPath.item; i <= lastIndexPath.item; i++) {
    [indexes addObject:[NSIndexPath indexPathForItem:i inSection:0]];
  }
  return indexes;

}

#pragma mark - UICollectionView DataSource delegates

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

  if (collectionView == self.summaryCollectionView) {

    WANewDaySummaryViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kWANewDaySummaryViewCellID forIndexPath:indexPath];
    NSAssert(cell, @"cell should be registered first");
    NSUInteger numOfDaySummaries = [self.daySummaries count];
    cell.representingDaySummary = self.daySummaries[numOfDaySummaries - indexPath.row - 1];
    return cell;

  } else if (collectionView == self.eventCollectionView) {

    WANewDayEventViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kWANewDayEventViewCellID forIndexPath:indexPath];
    NSAssert(cell, @"cell should be registered first");
    NSInteger numOfDayEvents = [self.dayEvents count];
    cell.representingDayEvent = self.dayEvents[numOfDayEvents - indexPath.row - 1];
    for (NSInteger i = (numOfDayEvents-indexPath.row-1)-2; i<=(numOfDayEvents-indexPath.row-1)+2; i++) {
      if (i >= 0 && i < numOfDayEvents) {
        [self.dayEvents[i] loadImages];
      }
    }
    if ((numOfDayEvents-indexPath.row-1)-3 >= 0) {
      [self.dayEvents[(numOfDayEvents-indexPath.row-1)-3] unloadImages];
    }
    if ((numOfDayEvents-indexPath.row-1)+3 < numOfDayEvents) {
      [self.dayEvents[(numOfDayEvents-indexPath.row-1)+3] unloadImages];
    }
    
    return cell;

  } else {

    NSAssert(NO, @"unexpected collection view %@", collectionView);
    return nil;

  }
  
}

@end
