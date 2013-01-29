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
#import "IIViewDeckController.h"
#import "IRBarButtonItem.h"
#import "WADayViewController.h"
#import "WAAppDelegate_iOS.h"

static NSInteger const DEFAULT_SUMMARY_PAGING_SIZE = 20;
static NSInteger const DEFAULT_EVENT_IMAGE_PAGING_SIZE = 5;

@interface WASummaryViewController ()

@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) NSDate *beginningDate;
@property (nonatomic, strong) WADaySummary *currentDaySummary;
@property (nonatomic, strong) WADaySummary *firstDaySummary;
@property (nonatomic, strong) WADaySummary *lastDaySummary;
@property (nonatomic, strong) WAEventPageView *currentEventPage;
@property (nonatomic, strong) NSMutableDictionary *daySummaries;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL scrollingSummaryPage;
@property (nonatomic) BOOL scrollingEventPage;
@property (nonatomic) BOOL reloading;

@property (nonatomic) WADayViewSupportedStyle presentingStyle;
@property (nonatomic) BOOL contextMenuOpened;

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

  self.presentingStyle = WAEventsViewStyle;

  self.backgroundImageView.clipsToBounds = YES;
  
  __weak WASummaryViewController *wSelf = self;
  self.navigationItem.leftBarButtonItem = WABarButtonItem([UIImage imageNamed:@"menu"], @"", ^{
    [wSelf.viewDeckController toggleLeftView];
  });
  
  self.navigationController.navigationBar.translucent = YES;
  self.navigationItem.titleView = [WAContextMenuViewController titleViewForContextMenu:self.presentingStyle
							 performSelector:@selector(contextMenuTapped)
							      withObject:self];

  [self.upperMaskView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.3]];
  [self.lowerMaskView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.6]];

  WAUser *user = [[WADataStore defaultStore] mainUserInContext:self.managedObjectContext];
  self.user = user;

  self.eventScrollView.delegate = self;
  self.summaryScrollView.delegate = self;
  
}

- (void)viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];

  [self reloadDaySummariesWithPagingSize:DEFAULT_SUMMARY_PAGING_SIZE];

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

  __block NSUInteger totalSummaryPagesCount = 0;
  __block NSUInteger totalEventPagesCount = 0;
  [self.daySummaries enumerateKeysAndObjectsUsingBlock:^(id key, WADaySummary *daySummary, BOOL *stop) {
    totalSummaryPagesCount += 1;
    totalEventPagesCount += [daySummary.eventPages count];
  }];
  self.summaryScrollView.contentSize = CGSizeMake(self.summaryScrollView.frame.size.width * totalSummaryPagesCount, self.summaryScrollView.frame.size.height);
  self.eventScrollView.contentSize = CGSizeMake(self.eventScrollView.frame.size.width * totalEventPagesCount, self.eventScrollView.frame.size.height);

}

- (void)layoutSummaryAndEventPages {

  NSParameterAssert([NSThread isMainThread]);
  
  __weak WASummaryViewController *wSelf = self;
  [self.daySummaries enumerateKeysAndObjectsUsingBlock:^(id key, WADaySummary *daySummary, BOOL *stop) {
    [daySummary.eventPages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CGRect frame = wSelf.eventScrollView.frame;
      frame.origin.x = frame.size.width * (daySummary.eventIndex + idx - wSelf.firstDaySummary.eventIndex);
      frame.origin.y = 0;
      WAEventPageView *view = obj;
      view.frame = frame;
    }];
    CGRect frame = wSelf.summaryScrollView.frame;
    frame.origin.x = frame.size.width * (daySummary.summaryIndex - wSelf.firstDaySummary.summaryIndex);
    frame.origin.y = 0;
    WASummaryPageView *view = daySummary.summaryPage;
    view.frame = frame;
  }];

  [self scrollToCurrentSummaryPageAnimated:NO];
  [self scrollToCurrentEventPageAnimated:NO];

}

- (void)scrollToCurrentSummaryPageAnimated:(BOOL)animated {

  if (animated) {
    self.scrollingSummaryPage = YES;    
    __weak WASummaryViewController *wSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
      [wSelf.summaryScrollView scrollRectToVisible:wSelf.currentDaySummary.summaryPage.frame animated:NO];
    } completion:^(BOOL finished) {
      wSelf.scrollingSummaryPage = NO;
    }];
  } else {
    [self.summaryScrollView scrollRectToVisible:self.currentDaySummary.summaryPage.frame animated:NO];
  }

}

- (void)scrollToCurrentEventPageAnimated:(BOOL)animated {

  if (animated) {
    self.scrollingEventPage = YES;
    __weak WASummaryViewController *wSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
      [wSelf.eventScrollView scrollRectToVisible:wSelf.currentEventPage.frame animated:NO];
    } completion:^(BOOL finished) {
      wSelf.scrollingEventPage = NO;
    }];
  } else {
    [self.eventScrollView scrollRectToVisible:self.currentEventPage.frame animated:NO];
  }

}

- (void)setScrollingEventPage:(BOOL)scrollingEventPage {

  NSParameterAssert([NSThread isMainThread]);
  _scrollingEventPage = scrollingEventPage;

}

- (void)setScrollingSummaryPage:(BOOL)scrollingSummaryPage {

  NSParameterAssert([NSThread isMainThread]);
  _scrollingSummaryPage = scrollingSummaryPage;

}

- (void)setReloading:(BOOL)reloading {

  NSParameterAssert([NSThread isMainThread]);
  _reloading = reloading;

}

- (void)setCurrentDaySummary:(WADaySummary *)currentDaySummary {

  NSParameterAssert([NSThread isMainThread]);

  if (currentDaySummary.summaryIndex >= _currentDaySummary.summaryIndex) {
    [self reloadEventPageImagesWithPagingSize:DEFAULT_EVENT_IMAGE_PAGING_SIZE];
  } else {
    [self reloadEventPageImagesWithPagingSize:(-DEFAULT_EVENT_IMAGE_PAGING_SIZE)];
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

  NSParameterAssert([NSThread isMainThread]);

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

- (void)reloadDaySummariesWithPagingSize:(NSInteger)pagingSize {
  
  if (self.reloading) {
    return;
  }

  self.reloading = YES;

  if (!self.currentDaySummary) {
    WADaySummary *currentDaySummary = [[WADaySummary alloc] initWithUser:self.user date:[self dayAtIndex:0] context:self.managedObjectContext];
    [self insertDaySummary:currentDaySummary atIndex:0];
    self.currentDaySummary = currentDaySummary;
    self.firstDaySummary = currentDaySummary;
    self.lastDaySummary = currentDaySummary;
  }
  WAOverlayBezel *bezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
  [bezel show];
  __weak WASummaryViewController *wSelf = self;
  int64_t delayInSeconds = 1.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    NSDate *recentDay = [[NSDate date] dayBegin];
    for (NSInteger idx = wSelf.currentDaySummary.summaryIndex; idx != wSelf.currentDaySummary.summaryIndex+pagingSize; idx += pagingSize/abs(pagingSize)) {
      BOOL isFutureDay = [[[wSelf dayAtIndex:idx] earlierDate:recentDay] isEqualToDate:recentDay];
      if (!isFutureDay && !wSelf.daySummaries[@(idx)]) {
        WADaySummary *daySummary = [[WADaySummary alloc] initWithUser:wSelf.user date:[wSelf dayAtIndex:idx] context:wSelf.managedObjectContext];
        [wSelf insertDaySummary:daySummary atIndex:idx];
        if (daySummary.summaryIndex > wSelf.lastDaySummary.summaryIndex) {
	wSelf.lastDaySummary = daySummary;
        }
        if (daySummary.summaryIndex < wSelf.firstDaySummary.summaryIndex) {
	wSelf.firstDaySummary = daySummary;
        }
      }
    }
    [wSelf resetContentSize];
    [wSelf layoutSummaryAndEventPages];
    [wSelf reloadEventPageImagesWithPagingSize:DEFAULT_EVENT_IMAGE_PAGING_SIZE];
    [bezel dismissWithAnimation:WAOverlayBezelAnimationFade];
    wSelf.reloading = NO;
  });
  
}

- (void)reloadEventPageImagesWithPagingSize:(NSInteger)pagingSize {

  if (pagingSize > 0) {
    for (NSInteger idx = self.currentDaySummary.summaryIndex; idx <= self.currentDaySummary.summaryIndex+pagingSize; idx++) {
      WADaySummary *daySummary = self.daySummaries[@(idx)];
      if (daySummary) {
        [daySummary.eventPages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WAEventPageView *eventPage, NSUInteger idx, BOOL *stop) {
	[eventPage loadImages];
        }];
      }
    }
    WADaySummary *daySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex-3*pagingSize-1)];
    if (daySummary) {
      for (WAEventPageView *eventPage in daySummary.eventPages) {
        [eventPage unloadImages];
      }
    }
  } else {
    for (NSInteger idx = self.currentDaySummary.summaryIndex; idx >= self.currentDaySummary.summaryIndex+pagingSize; idx--) {
      WADaySummary *daySummary = self.daySummaries[@(idx)];
      if (daySummary) {
        if (self.scrollingSummaryPage) {
	[daySummary.eventPages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WAEventPageView *eventPage, NSUInteger idx, BOOL *stop) {
	  [eventPage loadImages];
	}];
        } else {
	for (WAEventPageView *eventPage in daySummary.eventPages) {
	  [eventPage loadImages];
	}
        }
      }
    }
    WADaySummary *daySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex-3*pagingSize+1)];
    if (daySummary) {
      for (WAEventPageView *eventPage in daySummary.eventPages) {
        [eventPage unloadImages];
      }
    }
  }

}

- (NSInteger)indexOfDay:(NSDate *)day {

  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSUInteger flags = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSTimeZoneCalendarUnit;
  NSDateComponents *beginningDateComponents = [calendar components:flags fromDate:self.beginningDate];
  NSDateComponents *dateComponents = [calendar components:flags fromDate:day];
  return dateComponents.day - beginningDateComponents.day;

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
    NSAssert(self.daySummaries[@(idx-1)], @"previous day summary should exist");
    daySummary.eventIndex = [self.daySummaries[@(idx-1)] eventIndex] + [[self.daySummaries[@(idx-1)] eventPages] count];
  } else if (idx < 0) {
    NSAssert(self.daySummaries[@(idx+1)], @"previous day summary should exist");
    daySummary.eventIndex = [self.daySummaries[@(idx+1)] eventIndex] - [daySummary.eventPages count];
  } else {
    daySummary.eventIndex = 0;
  }

  self.daySummaries[@(idx)] = daySummary;

  __weak WASummaryViewController *wSelf = self;
  [daySummary.eventPages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(WAEventPageView *eventPage, NSUInteger idx, BOOL *stop) {
    [wSelf.eventScrollView addSubview:eventPage];
  }];
  [self.summaryScrollView addSubview:daySummary.summaryPage];

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

#pragma mark - Target actions

- (void)contextMenuTapped {

  __weak WASummaryViewController *wSelf = self;
  
  if (self.contextMenuOpened) {
    [self.childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if ([obj isKindOfClass:[WAContextMenuViewController class]]) {
        
        *stop = YES;
        WAContextMenuViewController *ddMenu = (WAContextMenuViewController*)obj;
        [ddMenu dismissContextMenu];
        
      }
    }];
    return;
  }
  
  __block WAContextMenuViewController *ddMenu = [[WAContextMenuViewController alloc] initForViewStyle:self.presentingStyle completion:^{
    
    [wSelf.navigationItem.leftBarButtonItem setEnabled:YES];
    [wSelf.navigationItem.rightBarButtonItem setEnabled:YES];
    
    wSelf.contextMenuOpened = NO;
    
  }];
  
  ddMenu.delegate = self;
  
  [ddMenu presentContextMenuInViewController:self];
  [self.navigationItem.leftBarButtonItem setEnabled:NO];
  [self.navigationItem.rightBarButtonItem setEnabled:NO];
  self.contextMenuOpened = YES;

}

#pragma mark - Context menu delegates

- (void) contextMenuItemDidSelect:(WADayViewSupportedStyle)itemStyle {
  
  NSDate *theDate = [self dayAtIndex:self.currentDaySummary.summaryIndex];
  
  WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
  [appDelegate.slidingMenu switchToViewStyle:itemStyle onDate:theDate];
  
}

#pragma mark - WADayViewController delegates

- (BOOL)jumpToDate:(NSDate *)date animated:(BOOL)animated {

  NSInteger idx = [self indexOfDay:date];
  if (!self.daySummaries[@(idx)]) {
    self.beginningDate = date;
    [self reloadDaySummariesWithPagingSize:DEFAULT_SUMMARY_PAGING_SIZE];
  } else {
    NSAssert(NO, @"WASummaryViewController should be recreated");
  }

  return YES;

}

- (void)jumpToRecentDay {

  self.beginningDate = [[NSDate date] dayBegin];
  self.currentDaySummary = nil;
  [self reloadDaySummariesWithPagingSize:DEFAULT_SUMMARY_PAGING_SIZE];

}

#pragma mark - UIScrollView delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
  CGFloat pageWidth = scrollView.frame.size.width;
  if (scrollView.contentOffset.x > scrollView.contentSize.width - pageWidth) {
    [self reloadDaySummariesWithPagingSize:DEFAULT_SUMMARY_PAGING_SIZE];
    return;
  }
  if (scrollView.contentOffset.x < 0) {
    [self reloadDaySummariesWithPagingSize:(-DEFAULT_SUMMARY_PAGING_SIZE)];
    return;
  }

  NSInteger pageIndex = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;

  if (scrollView == self.summaryScrollView) {

    if (self.reloading || self.scrollingEventPage) {
      return;
    }

    if (self.currentDaySummary.summaryIndex != pageIndex + self.firstDaySummary.summaryIndex) {

      self.currentDaySummary = self.daySummaries[@(pageIndex + self.firstDaySummary.summaryIndex)];
      [self scrollToCurrentEventPageAnimated:YES];

    }
    
  } else {

    if (self.reloading || self.scrollingSummaryPage) {
      return;
    }

    if (self.currentDaySummary.eventIndex > pageIndex + self.firstDaySummary.eventIndex) {

      self.currentDaySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex-1)];
      [self scrollToCurrentSummaryPageAnimated:YES];

    } else if (self.currentDaySummary.eventIndex + (NSInteger)[self.currentDaySummary.eventPages count] <= pageIndex + self.firstDaySummary.eventIndex) {

      self.currentDaySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex+1)];
      [self scrollToCurrentSummaryPageAnimated:YES];

    } else if (self.eventPageControll.currentPage != pageIndex + self.firstDaySummary.eventIndex - self.currentDaySummary.eventIndex){
      
      self.eventPageControll.currentPage = pageIndex + self.firstDaySummary.eventIndex - self.currentDaySummary.eventIndex;
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
