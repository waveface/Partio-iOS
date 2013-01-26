//
//  WASummaryViewController.m
//  wammer
//
//  Created by kchiu on 13/1/21.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASummaryViewController.h"
#import "WADataStore.h"
#import "WAArticle.h"
#import <StackBluriOS/UIImage+StackBlur.h>
#import "NSDate+WAAdditions.h"
#import "WAUser.h"
#import "WAEventPageView.h"
#import "WASummaryPageView.h"
#import "WADaySummary.h"
#import "WAOverlayBezel.h"
#import "UIImageView+WAAdditions.h"
#import "WAFile+ImplicitBlobFulfillment.h"

static NSInteger const SUMMARY_PAGES_WINDOW_SIZE = 20;
static NSInteger const SUMMARY_IMAGES_WINDOW_SIZE = 3;

@interface WASummaryViewController ()

@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) NSDate *beginningDate;
@property (nonatomic, strong) WADaySummary *currentDaySummary;
@property (nonatomic, strong) WAEventPageView *currentEventPage;
@property (nonatomic, strong) NSMutableDictionary *daySummaries;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL scrollingSummaryPage;
@property (nonatomic) BOOL scrollingEventPage;
@property (nonatomic) BOOL needsReload;
@property (nonatomic) NSInteger needingAllocatedSummaryPagesCount;
@property (nonatomic) NSInteger needingAllocatedEventPagesCount;

@end

@implementation WASummaryViewController

- (id)initWithDate:(NSDate *)date {

  self = [super init];
  if (self) {
    self.beginningDate = date ? date : [[NSDate date] dayBegin];
    self.daySummaries = [NSMutableDictionary dictionary];
    self.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  }
  return self;

}

- (void)viewDidLoad {

  [super viewDidLoad];

  self.wantsFullScreenLayout = YES;
  self.backgroundImageView.clipsToBounds = YES;
  [self.upperMaskView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.3]];
  [self.lowerMaskView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.6]];

  WAUser *user = [[WADataStore defaultStore] mainUserInContext:self.managedObjectContext];
  self.user = user;

  self.eventScrollView.delegate = self;
  self.summaryScrollView.delegate = self;
  
}

- (void)viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];

  [self reloadDaySummaries];

}

- (void)viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];
  
  // Set scrollView's contentSize only works here if auto-layout is enabled
  // Ref: http://stackoverflow.com/questions/12619786/embed-imageview-in-scrollview-with-auto-layout-on-ios-6
  [self resetContentSize];
  
}

- (NSUInteger) supportedInterfaceOrientations {
  
  if (isPad())
    return UIInterfaceOrientationMaskAll;
  else
    return UIInterfaceOrientationMaskPortrait;
  
}

- (BOOL) shouldAutorotate {
  
  return YES;
  
}

- (void)resetContentSize {

  NSParameterAssert([NSThread isMainThread]);

  __block NSUInteger totalEventPagesCount = 0;
  [self.daySummaries enumerateKeysAndObjectsUsingBlock:^(id key, WADaySummary *daySummary, BOOL *stop) {
    totalEventPagesCount += [daySummary.eventPages count];
  }];
  self.eventScrollView.contentSize = CGSizeMake(self.eventScrollView.frame.size.width * self.needingAllocatedEventPagesCount, self.eventScrollView.frame.size.height);
  self.summaryScrollView.contentSize = CGSizeMake(self.summaryScrollView.frame.size.width * self.needingAllocatedSummaryPagesCount, self.summaryScrollView.frame.size.height);

}

- (void)setScrollingEventPage:(BOOL)scrollingEventPage {

  NSParameterAssert([NSThread isMainThread]);
  _scrollingEventPage = scrollingEventPage;

}

- (void)setScrollingSummaryPage:(BOOL)scrollingSummaryPage {

  NSParameterAssert([NSThread isMainThread]);
  _scrollingSummaryPage = scrollingSummaryPage;

}

- (void)setNeedsReload:(BOOL)needsReload {

  NSParameterAssert([NSThread isMainThread]);
  _needsReload = needsReload;

}

- (void)setCurrentDaySummary:(WADaySummary *)currentDaySummary {

  NSParameterAssert([NSThread isMainThread]);

  if (currentDaySummary.summaryIndex >= _currentDaySummary.summaryIndex) {
    for (NSInteger idx = currentDaySummary.summaryIndex; idx <= currentDaySummary.summaryIndex+SUMMARY_IMAGES_WINDOW_SIZE; idx++) {
      WADaySummary *daySummary = self.daySummaries[@(idx)];
      if (daySummary) {
        for (WAEventPageView *eventPage in currentDaySummary.eventPages) {
	[eventPage loadImages];
        }
        [daySummary.eventPages[0] loadImages];
      }
    }
    for (WAEventPageView *eventPage in [self.daySummaries[@(currentDaySummary.summaryIndex-SUMMARY_IMAGES_WINDOW_SIZE-1)] eventPages]) {
      [eventPage unloadImages];
    }
  } else {
    for (NSInteger idx = currentDaySummary.summaryIndex; idx >= currentDaySummary.summaryIndex-SUMMARY_IMAGES_WINDOW_SIZE; idx--) {
      WADaySummary *daySummary = self.daySummaries[@(idx)];
      if (daySummary) {
        [daySummary.eventPages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WAEventPageView *eventPage, NSUInteger idx, BOOL *stop) {
	[eventPage loadImages];
        }];
        if (self.scrollingSummaryPage) {
	[daySummary.eventPages[0] loadImages];
        }
      }
    }
    for (WAEventPageView *eventPage in [self.daySummaries[@(currentDaySummary.summaryIndex+SUMMARY_IMAGES_WINDOW_SIZE+1)] eventPages]) {
      [eventPage unloadImages];
    }
  }

  NSInteger oldEventIndex = _currentDaySummary.eventIndex;

  _currentDaySummary = currentDaySummary;
  
  NSInteger pageControllIndex = 0;
  
  if (self.scrollingEventPage && oldEventIndex > _currentDaySummary.eventIndex) {
    pageControllIndex = [_currentDaySummary.eventPages count] - 1;
  }
  
  self.eventPageControll.numberOfPages = [currentDaySummary.articles count];
  self.eventPageControll.currentPage = pageControllIndex;

  self.currentEventPage = currentDaySummary.eventPages[pageControllIndex];

}

- (void)setCurrentEventPage:(WAEventPageView *)currentEventPage {

  [_currentEventPage irRemoveObserverBlocksForKeyPath:@"blurredBackgroundImage"];

  _currentEventPage = currentEventPage;

  [currentEventPage loadImages];
  [self loadBackgroundImageFromEventPage:currentEventPage];

}

- (void)loadBackgroundImageFromEventPage:(WAEventPageView *)eventPage {
  
  __weak WASummaryViewController *wSelf = self;
  [eventPage irObserve:@"blurredBackgroundImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    if (wSelf.currentEventPage != eventPage) {
      return;
    }
    [wSelf.backgroundImageView addCrossFadeAnimationWithTargetImage:toValue];
  }];

}

- (void)reloadDaySummaries {
  
  if (!self.currentDaySummary || !self.daySummaries[@(self.currentDaySummary.summaryIndex+1)] || !self.daySummaries[@(self.currentDaySummary.summaryIndex-1)]) {
    self.needsReload = YES;
    self.summaryScrollView.scrollEnabled = NO;
    self.eventScrollView.scrollEnabled = NO;
    if (self.scrollingSummaryPage || self.scrollingEventPage) {
      // will reload after scrolling finished
      return;
    }
    [self reloadDaySummariesIfNeeded];
  }
  
}

- (void)reloadDaySummariesIfNeeded {

  NSParameterAssert([NSThread isMainThread]);

  __weak WASummaryViewController *wSelf = self;
  if (self.needsReload) {
    WAOverlayBezel *bezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
    [bezel show];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      WADaySummary *currentDaySummary = wSelf.currentDaySummary;
      if (!currentDaySummary) {
        currentDaySummary = [[WADaySummary alloc] initWithUser:wSelf.user date:[wSelf dayAtIndex:0] context:wSelf.managedObjectContext];
        [wSelf insertDaySummary:currentDaySummary atIndex:0];
      }
      for (NSInteger idx = currentDaySummary.summaryIndex-2*SUMMARY_PAGES_WINDOW_SIZE; idx < currentDaySummary.summaryIndex-SUMMARY_PAGES_WINDOW_SIZE; idx++) {
        if (idx >= 0) {
	if (wSelf.daySummaries[@(idx)]) {
	  [wSelf removeDaySummaryAtIndex:idx];
	}
        }
      }
      for (NSInteger idx = currentDaySummary.summaryIndex+SUMMARY_PAGES_WINDOW_SIZE; idx < currentDaySummary.summaryIndex+2*SUMMARY_PAGES_WINDOW_SIZE; idx++) {
        if (idx >= 0) {
	if (wSelf.daySummaries[@(idx)]) {
	  [wSelf removeDaySummaryAtIndex:idx];
	}
        }
      }
      for (NSInteger idx = currentDaySummary.summaryIndex; idx < currentDaySummary.summaryIndex+SUMMARY_PAGES_WINDOW_SIZE; idx++) {
        if (idx >= 0) {
	if (!wSelf.daySummaries[@(idx)]) {
	  WADaySummary *daySummary = [[WADaySummary alloc] initWithUser:self.user date:[self dayAtIndex:idx] context:self.managedObjectContext];
	  [wSelf insertDaySummary:daySummary atIndex:idx];
	}
        }
      }
      for (NSInteger idx = currentDaySummary.summaryIndex; idx >= currentDaySummary.summaryIndex-SUMMARY_PAGES_WINDOW_SIZE; idx--) {
        if (idx >= 0) {
	if (!wSelf.daySummaries[@(idx)]) {
	  WADaySummary *daySummary = [[WADaySummary alloc] initWithUser:self.user date:[self dayAtIndex:idx] context:self.managedObjectContext];
	  [wSelf insertDaySummary:daySummary atIndex:idx];
	}
        }
      }
      // load images in event page
      wSelf.currentDaySummary = currentDaySummary;
      [wSelf resetContentSize];
      wSelf.needsReload = NO;
      wSelf.summaryScrollView.scrollEnabled = YES;
      wSelf.eventScrollView.scrollEnabled = YES;
      [bezel dismissWithAnimation:WAOverlayBezelAnimationFade];
    }];
  }

}

- (NSDate *)dayAtIndex:(NSInteger)idx {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSUInteger flags = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSTimeZoneCalendarUnit;
  NSDateComponents *dateComponents = [calendar components:flags fromDate:self.beginningDate];
  dateComponents.day -= idx;
  return [calendar dateFromComponents:dateComponents];
  
}

- (void)insertDaySummary:(WADaySummary *)daySummary atIndex:(NSInteger)idx {
  
  daySummary.summaryIndex = idx;
  if (idx > 0) {
    if (idx > self.currentDaySummary.summaryIndex) {
      NSAssert(self.daySummaries[@(idx-1)], @"previous day summary should exist");
      daySummary.eventIndex = [self.daySummaries[@(idx-1)] eventIndex] + [[self.daySummaries[@(idx-1)] eventPages] count];
    } else {
      NSAssert(self.daySummaries[@(idx+1)], @"previous day summary should exist");
      daySummary.eventIndex = [self.daySummaries[@(idx+1)] eventIndex] - [daySummary.eventPages count];
    }
  } else {
    daySummary.eventIndex = 0;
  }
  self.daySummaries[@(idx)] = daySummary;
  self.needingAllocatedSummaryPagesCount += 1;
  self.needingAllocatedEventPagesCount += [daySummary.eventPages count];
  for (UIView *page in daySummary.eventPages) {
    [self.eventScrollView addSubview:page];
  }
  [self.summaryScrollView addSubview:daySummary.summaryPage];
  
  __weak WASummaryViewController *wSelf = self;
  [daySummary.eventPages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CGRect frame = wSelf.eventScrollView.frame;
    frame.origin.x = frame.size.width * (daySummary.eventIndex + idx);
    frame.origin.y = 0;
    WAEventPageView *view = obj;
    view.frame = frame;
  }];
  CGRect frame = self.summaryScrollView.frame;
  frame.origin.x = frame.size.width * (daySummary.summaryIndex);
  frame.origin.y = 0;
  WASummaryPageView *view = daySummary.summaryPage;
  view.frame = frame;
  
}

- (void)removeDaySummaryAtIndex:(NSInteger)idx {

  WADaySummary *daySummary = self.daySummaries[@(idx)];
  for (UIView *page in daySummary.eventPages) {
    [page removeFromSuperview];
  }
  [daySummary.summaryPage removeFromSuperview];
  [self.daySummaries removeObjectForKey:@(idx)];

}

+ (NSOperationQueue *)sharedBackgroundImageDisplayQueue {

  static NSOperationQueue *queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
  });
  return queue;

}

+ (UIImage *)sharedBackgroundImage {

  static UIImage *backgroundImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    backgroundImage = [[UIImage imageNamed:@"LoginBackground-Portrait"] stackBlur:5.0];
  });
  return backgroundImage;

}

#pragma mark UIScrollView delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
  CGFloat pageWidth = scrollView.frame.size.width;
  NSInteger pageIndex = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;

  __weak WASummaryViewController *wSelf = self;

  if (scrollView == self.summaryScrollView) {

    if (self.scrollingEventPage) {
      return;
    }

    if (self.currentDaySummary.summaryIndex != pageIndex) {

      self.currentDaySummary = self.daySummaries[@(pageIndex)];
      [self reloadDaySummaries];
      self.scrollingEventPage = YES;
      [UIView animateWithDuration:0.3 animations:^{
        [wSelf.eventScrollView setContentOffset:CGPointMake(wSelf.eventScrollView.frame.size.width*wSelf.currentDaySummary.eventIndex, 0)];
      } completion:^(BOOL finished) {
        wSelf.scrollingEventPage = NO;
        [wSelf reloadDaySummariesIfNeeded];
      }];

    }

  } else {

    if (self.scrollingSummaryPage) {
      return;
    }

    if (self.currentDaySummary.eventIndex > pageIndex) {

      self.currentDaySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex-1)];
      [self reloadDaySummaries];
      self.scrollingSummaryPage = YES;
      [UIView animateWithDuration:0.3 animations:^{
        [wSelf.summaryScrollView setContentOffset:CGPointMake(wSelf.summaryScrollView.frame.size.width*wSelf.currentDaySummary.summaryIndex, 0)];
      } completion:^(BOOL finished) {
        wSelf.scrollingSummaryPage = NO;
        [wSelf reloadDaySummariesIfNeeded];
      }];

    } else if (self.currentDaySummary.eventIndex + [self.currentDaySummary.eventPages count] <= pageIndex) {

      self.currentDaySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex+1)];
      [self reloadDaySummaries];
      self.scrollingSummaryPage = YES;
      [UIView animateWithDuration:0.3 animations:^{
        [wSelf.summaryScrollView setContentOffset:CGPointMake(wSelf.summaryScrollView.frame.size.width*wSelf.currentDaySummary.summaryIndex, 0)];
      } completion:^(BOOL finished) {
        wSelf.scrollingSummaryPage = NO;
        [wSelf reloadDaySummariesIfNeeded];
      }];

    } else if (self.eventPageControll.currentPage != pageIndex - self.currentDaySummary.eventIndex){
      
      self.eventPageControll.currentPage = pageIndex - self.currentDaySummary.eventIndex;
      self.currentEventPage = self.currentDaySummary.eventPages[self.eventPageControll.currentPage];

    }
  }
  
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  
  if (scrollView == self.eventScrollView) {
    self.scrollingEventPage = YES;
  } else {
    self.scrollingSummaryPage = YES;
  }
  
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

  if (scrollView == self.eventScrollView) {
    self.scrollingEventPage = NO;
  } else {
    self.scrollingSummaryPage = NO;
  }
  
}

@end
