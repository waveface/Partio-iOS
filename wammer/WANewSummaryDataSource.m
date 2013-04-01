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
#import "WAFile.h"
#import "WAPhotoDay.h"
#import "WAFileAccessLog.h"
#import "WADocumentDay.h"
#import "WAWebpageDay.h"
#import "WAUser.h"

@interface WANewSummaryDataSource ()

@property (nonatomic, strong) WAUser *user;
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

@property (nonatomic, strong) NSMutableSet *changedDaySummaries;
@property (nonatomic) BOOL dayEventsCountChanged;

@end

@implementation WANewSummaryDataSource

- (id)initWithDate:(NSDate *)aDate {

  self = [super init];
  if (self) {
    WADataStore *ds = [WADataStore defaultStore];
    self.user = [ds mainUserInContext:[ds defaultAutoUpdatedMOC]];
    self.daySummaries = [NSMutableArray array];
    self.dayEvents = [NSMutableArray array];
    self.firstDate = aDate;
    self.lastDate = aDate;
    self.currentDate = aDate;
    [self loadMoreDays:20 since:self.firstDate];
  }
  return self;

}

- (BOOL)loadMoreDays:(NSUInteger)numOfDays since:(NSDate *)aDate {
  
  if (![self.daySummaries count]) {
    WANewDaySummary *daySummary = [[WANewDaySummary alloc] init];
    daySummary.date = aDate;
    daySummary.user = self.user;
    [daySummary reloadData];
    [self.daySummaries addObject:daySummary];
  }

  if ([aDate isEqualToDate:self.firstDate]) {
    for (NSInteger i = 1; i <= numOfDays; i++) {
      WANewDaySummary *daySummary = [[WANewDaySummary alloc] init];
      daySummary.date = [self.firstDate dateOfPreviousNumOfDays:i];
      daySummary.user = self.user;
      [daySummary reloadData];
      [self.daySummaries insertObject:daySummary atIndex:0];
    }
    self.firstDate = [self.daySummaries[0] date];
  } else if ([aDate isEqualToDate:self.lastDate]) {
    NSDate *currentDate = [[NSDate date] dayBegin];
    if ([aDate isEqualToDate:currentDate]) {
      return NO;
    }
    for (NSInteger i = 1; i <= numOfDays; i++) {
      WANewDaySummary *daySummary = [[WANewDaySummary alloc] init];
      daySummary.date = [self.lastDate dateOfNextNumOfDays:i];
      daySummary.user = self.user;
      if ([daySummary.date compare:currentDate] == NSOrderedDescending) {
        // do not load future days
        break;
      }
      [daySummary reloadData];
      [self.daySummaries addObject:daySummary];
    }
    self.lastDate = [[self.daySummaries lastObject] date];
  } else {
    return NO;
  }
  
  [self resetFetchedResultsControllers];

  return YES;

}

- (void)resetFetchedResultsControllers {

  NSManagedObjectContext *moc = [[WADataStore defaultStore] defaultAutoUpdatedMOC];

  if (!self.articleFetchedResultsController) {
    NSFetchRequest *articleFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAArticle"];
    [articleFetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"eventStartDate" ascending:YES]]];
    self.articleFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:articleFetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    self.articleFetchedResultsController.delegate = self;
  }
  [self.articleFetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"eventStartDate >= %@ AND eventStartDate <= %@ AND event = TRUE AND hidden = FALSE ", self.firstDate, [self.lastDate dayEnd]]];
  [self.articleFetchedResultsController performFetch:nil];
  NSArray *articles = self.articleFetchedResultsController.fetchedObjects;

  if ([self.dayEvents count]) {
    // load more days
    NSDate *firstDayEventDate = [self.dayEvents[0] startTime];
    NSDate *lastDayEventDate = [[self.dayEvents lastObject] startTime];
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

- (NSIndexPath *)indexPathOfDaySummaryOnDate:(NSDate *)aDate {

  NSUInteger itemIndex = [self indexOfDaySummaryOnDate:aDate];
  return [NSIndexPath indexPathForItem:itemIndex inSection:0];

}

- (NSUInteger)indexOfDaySummaryOnDate:(NSDate *)aDate {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSUInteger flags = NSDayCalendarUnit|NSTimeZoneCalendarUnit;
  NSDateComponents *dateComponents = [calendar components:flags fromDate:self.firstDate toDate:aDate options:0];
  return dateComponents.day;
  
}

- (NSIndexPath *)indexPathOfFirstDayEventOnDate:(NSDate *)aDate {

  NSIndexSet *indexes = [self indexesOfEventsOnDate:aDate];
  NSUInteger itemIndex = [indexes firstIndex];
  NSAssert(itemIndex != NSNotFound, @"There should be a day event for any searchable dates");

  return [NSIndexPath indexPathForItem:itemIndex inSection:0];

}

- (NSIndexSet *)indexesOfEventsOnDate:(NSDate *)aDate {
  
  WANewDayEvent *leadingDayEvent = [[WANewDayEvent alloc] initWithArticle:nil date:[aDate dayBegin]];
  NSUInteger leadingSentinel = [self.dayEvents indexOfObject:leadingDayEvent
                                               inSortedRange:NSMakeRange(0, [self.dayEvents count])
                                                     options:NSBinarySearchingInsertionIndex
                                             usingComparator:^NSComparisonResult(WANewDayEvent *dayEvent1, WANewDayEvent *dayEvent2) {
                                               return [dayEvent1.startTime compare:dayEvent2.startTime];
                                             }];
  WANewDayEvent *trailingDayEvent = [[WANewDayEvent alloc] initWithArticle:nil date:[aDate dayEnd]];
  NSUInteger trailingSentinel = [self.dayEvents indexOfObject:trailingDayEvent
                                                inSortedRange:NSMakeRange(0, [self.dayEvents count])
                                                      options:NSBinarySearchingInsertionIndex
                                              usingComparator:^NSComparisonResult(WANewDayEvent *dayEvent1, WANewDayEvent *dayEvent2) {
                                                return [dayEvent1.startTime compare:dayEvent2.startTime];
                                              }];
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(leadingSentinel, trailingSentinel-leadingSentinel)];
  
  return indexes;
  
}

- (NSIndexPath *)indexPathOfLastDayEventOnDate:(NSDate *)aDate {

  NSIndexSet *indexes = [self indexesOfEventsOnDate:aDate];
  NSUInteger itemIndex = [indexes lastIndex];
  NSAssert(itemIndex != NSNotFound, @"There should be a day event for any searchable dates");
  
  return [NSIndexPath indexPathForItem:(itemIndex) inSection:0];

}

- (NSIndexPath *)indexPathOfDayEvent:(WANewDayEvent *)aDayEvent {

  NSUInteger itemIndex = [self.dayEvents indexOfObjectPassingTest:^BOOL(WANewDayEvent *dayEvent, NSUInteger idx, BOOL *stop) {
    return [dayEvent.startTime isEqualToDate:aDayEvent.startTime];
  }];

  NSAssert(itemIndex != NSNotFound, @"There should be a day event for any searchable day events");
  
  return [NSIndexPath indexPathForItem:(itemIndex) inSection:0];
  
}

- (NSDate *)dateOfDaySummaryAtIndexPath:(NSIndexPath *)anIndexPath {

  WANewDaySummary *daySummary = self.daySummaries[anIndexPath.row];
  return daySummary.date;

}

- (NSDate *)dateOfDayEventAtIndexPath:(NSIndexPath *)anIndexPath {

  WANewDayEvent *dayEvent = self.dayEvents[anIndexPath.item];
  return [dayEvent.startTime dayBegin];

}

- (WANewDaySummary *)daySummaryAtIndexPath:(NSIndexPath *)anIndexPath {

  if ([anIndexPath row] >= [_daySummaries count])
    return nil;
  
  return _daySummaries[[anIndexPath row]];

}

- (WANewDayEvent *)dayEventAtIndexPath:(NSIndexPath *)anIndexPath {
  
  if ([anIndexPath row] >= [_dayEvents count])
    return nil;
  
  return _dayEvents[anIndexPath.item];

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
    cell.representingDaySummary = self.daySummaries[indexPath.row];
    return cell;

  } else if (collectionView == self.eventCollectionView) {

    WANewDayEventViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kWANewDayEventViewCellID forIndexPath:indexPath];
    NSAssert(cell, @"cell should be registered first");
    
    NSInteger numOfDayEvents = [self.dayEvents count];
    cell.representingDayEvent = self.dayEvents[indexPath.row];
    
    NSDate *dateOfPreviousDay = [[self dateOfDayEventAtIndexPath:indexPath] dateOfPreviousDay];
    NSDate *dateOfFollowingDay = [[self dateOfDayEventAtIndexPath:indexPath] dateOfFollowingDay];
    if ([dateOfPreviousDay compare:self.firstDate] != NSOrderedAscending) {
      NSIndexPath *indexPathOfPreviousLastDayEvent = [self indexPathOfLastDayEventOnDate:dateOfPreviousDay];
      [self.dayEvents[indexPathOfPreviousLastDayEvent.item] loadImages];
    }
    for (NSInteger i = indexPath.row-1; i<=indexPath.row+1; i++) {
      if (i >= 0 && i < numOfDayEvents) {
        [self.dayEvents[i] loadImages];
      }
    }
    if ([dateOfFollowingDay compare:self.lastDate] != NSOrderedDescending) {
      NSIndexPath *indexPathOfNextFirstDayEvent = [self indexPathOfFirstDayEventOnDate:dateOfFollowingDay];
      [self.dayEvents[indexPathOfNextFirstDayEvent.item] loadImages];
    }
    
    if (indexPath.row-2 >= 0) {
      if ([dateOfPreviousDay compare:self.firstDate] != NSOrderedAscending) {
        NSIndexPath *indexPathOfPreviousLastDayEvent = [self indexPathOfLastDayEventOnDate:dateOfPreviousDay];
        if (indexPath.row-2 != indexPathOfPreviousLastDayEvent.item) {
          [self.dayEvents[indexPath.row-2] unloadImages];
        }
      }
    }
    if (indexPath.row+2 < numOfDayEvents) {
      if ([dateOfFollowingDay compare:self.lastDate] != NSOrderedDescending) {
        NSIndexPath *indexPathOfNextFirstDayEvent = [self indexPathOfFirstDayEventOnDate:dateOfFollowingDay];
        if (indexPath.row+2 != indexPathOfNextFirstDayEvent.item) {
          [self.dayEvents[indexPath.row+2] unloadImages];
        }
      }
    }
    
    NSDate *dateOfPrevious2Day = [[self dateOfDayEventAtIndexPath:indexPath] dateOfPreviousNumOfDays:2];
    NSDate *dateOfFollowing2Day = [[self dateOfDayEventAtIndexPath:indexPath] dateOfNextNumOfDays:2];
    if ([dateOfPrevious2Day compare:self.firstDate] != NSOrderedAscending) {
      NSIndexPath *indexPathOf2ndPreviousLastDayEvent= [self indexPathOfLastDayEventOnDate:dateOfPrevious2Day];
      [self.dayEvents[indexPathOf2ndPreviousLastDayEvent.item] unloadImages];
    }
    if ([dateOfFollowing2Day compare:self.lastDate] != NSOrderedDescending) {
      NSIndexPath *indexPathOf2ndNextFirstDayEvent = [self indexPathOfFirstDayEventOnDate:dateOfFollowing2Day];
      [self.dayEvents[indexPathOf2ndNextFirstDayEvent.item] unloadImages];
    }
    
    
    return cell;

  } else {

    NSAssert(NO, @"unexpected collection view %@", collectionView);
    return nil;

  }
  
}

#pragma mark - NSFetchedResultsController delegates

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
  
  self.changedDaySummaries = [NSMutableSet set];
  self.dayEventsCountChanged = NO;

}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
  
  switch (type) {
      
    case NSFetchedResultsChangeInsert:
      if (controller == self.articleFetchedResultsController) {
        WAArticle *article = anObject;
        NSDate *date = [article.eventStartDate dayBegin];
        NSUInteger daySummaryIndex = [self indexOfDaySummaryOnDate:date];
        [self.changedDaySummaries addObject:self.daySummaries[daySummaryIndex]];

        // remove no event day if needed
        NSIndexSet *dayEventIndexes = [self indexesOfEventsOnDate:date];
        NSUInteger itemIndex = [dayEventIndexes firstIndex];
        NSAssert(itemIndex != NSNotFound, @"there should be a day event for any date");
        if ([(WANewDayEvent *)self.dayEvents[itemIndex] style] == WADayEventStyleNone) {
          [self.dayEvents removeObjectAtIndex:[dayEventIndexes firstIndex]];
        }

        // insert new day event to self.dayEvents
        WANewDayEvent *dayEvent = [[WANewDayEvent alloc] initWithArticle:article date:date];
        NSUInteger insertIndex = [self.dayEvents indexOfObject:dayEvent inSortedRange:NSMakeRange(0, [self.dayEvents count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(WANewDayEvent *dayEvent1, WANewDayEvent *dayEvent2) {
          return [dayEvent1.startTime compare:dayEvent2.startTime];
        }];
        [self.dayEvents insertObject:dayEvent atIndex:insertIndex];
        self.dayEventsCountChanged = YES;
      } else if (controller == self.photoFetchedResultsController) {
        WAFile *file = anObject;
        NSUInteger index = [self indexOfDaySummaryOnDate:file.photoDay.day];
        [self.changedDaySummaries addObject:self.daySummaries[index]];
      } else if (controller == self.documentFetchedResultsController) {
        WAFileAccessLog *fileAccessLog = anObject;
        NSUInteger index = [self indexOfDaySummaryOnDate:fileAccessLog.day.day];
        [self.changedDaySummaries addObject:self.daySummaries[index]];
      } else if (controller == self.webpageFetchedResultsController) {
        WAFileAccessLog *fileAccessLog = anObject;
        NSUInteger index = [self indexOfDaySummaryOnDate:fileAccessLog.dayWebpages.day];
        [self.changedDaySummaries addObject:self.daySummaries[index]];
      }
      break;
      
    case NSFetchedResultsChangeUpdate:
      if (controller == self.articleFetchedResultsController) {
        WAArticle *article = anObject;
        if ([article.hidden boolValue]) {
          NSDate *date = [article.eventStartDate dayBegin];
          NSUInteger daySummaryIndex = [self indexOfDaySummaryOnDate:date];
          [self.changedDaySummaries addObject:self.daySummaries[daySummaryIndex]];
          NSUInteger removeIndex = [self.dayEvents indexOfObjectPassingTest:^BOOL(WANewDayEvent *dayEvent, NSUInteger idx, BOOL *stop) {
            return [dayEvent.representingArticle.identifier isEqualToString:article.identifier];
          }];
          NSAssert(removeIndex != NSNotFound, @"there should be a day event for the updated article");
          [self.dayEvents removeObjectAtIndex:removeIndex];
          self.dayEventsCountChanged = YES;
        }
      }
      
    default:
      break;
      
  }
  
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {

  for (WANewDaySummary *daySummary in self.changedDaySummaries) {
    [daySummary reloadData];
  }

  self.changedDaySummaries = nil;

  if (self.dayEventsCountChanged) {
    if ([self.delegate respondsToSelector:@selector(refreshViews)]) {
      [self.delegate refreshViews];
    }
    self.dayEventsCountChanged = NO;
  }
  
}

@end
