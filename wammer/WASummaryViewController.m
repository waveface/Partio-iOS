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

static NSInteger const SUMMARY_PAGES_WINDOW_SIZE = 20;
static NSInteger const SUMMARY_IMAGES_WINDOW_SIZE = 5;

@interface WASummaryViewController ()

@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) NSDate *beginningDate;
@property (nonatomic, strong) WADaySummary *currentDaySummary;
@property (nonatomic, strong) WAEventPageView *currentEventPage;
@property (nonatomic, strong) NSMutableDictionary *daySummaries;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL scrollingSummaryPage;
@property (nonatomic) BOOL scrollingEventPage;
@property (nonatomic) BOOL reloading;
@property (nonatomic) NSInteger needingAllocatedSummaryPagesCount;
@property (nonatomic) NSInteger needingAllocatedEventPagesCount;
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

- (void)setReloading:(BOOL)reloading {

  NSParameterAssert([NSThread isMainThread]);
  _reloading = reloading;

}

- (void)setCurrentDaySummary:(WADaySummary *)currentDaySummary {

  NSParameterAssert([NSThread isMainThread]);

  if (currentDaySummary.summaryIndex >= _currentDaySummary.summaryIndex) {
    for (NSInteger idx = currentDaySummary.summaryIndex; idx <= currentDaySummary.summaryIndex+SUMMARY_IMAGES_WINDOW_SIZE; idx++) {
      WADaySummary *daySummary = self.daySummaries[@(idx)];
      if (daySummary) {
        for (WAEventPageView *eventPage in daySummary.eventPages) {
	[eventPage loadImages];
        }
        [daySummary.eventPages[0] loadImages];
      }
    }
    WADaySummary *daySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex-3*SUMMARY_IMAGES_WINDOW_SIZE-1)];
    if (daySummary) {
      for (WAEventPageView *eventPage in daySummary.eventPages) {
        [eventPage unloadImages];
      }
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
    WADaySummary *daySummary = self.daySummaries[@(currentDaySummary.summaryIndex+3*SUMMARY_IMAGES_WINDOW_SIZE+1)];
    if (daySummary) {
      for (WAEventPageView *eventPage in daySummary.eventPages) {
        [eventPage unloadImages];
      }
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

- (void)reloadDaySummaries {
  
  if (self.reloading) {
    return;
  }

  self.reloading = YES;

  WADaySummary *currentDaySummary = self.currentDaySummary;
  if (!currentDaySummary) {
    currentDaySummary = [[WADaySummary alloc] initWithUser:self.user date:[self dayAtIndex:0] context:self.managedObjectContext];
    [self insertDaySummary:currentDaySummary atIndex:0];
    self.currentEventPage = currentDaySummary.eventPages[0];
  }
  WAOverlayBezel *bezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
  [bezel show];
  __weak WASummaryViewController *wSelf = self;
  int64_t delayInSeconds = 1.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    for (NSInteger idx = currentDaySummary.summaryIndex; idx < currentDaySummary.summaryIndex+SUMMARY_PAGES_WINDOW_SIZE; idx++) {
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
    wSelf.reloading = NO;
    [bezel dismissWithAnimation:WAOverlayBezelAnimationFade];
  });
  
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

#pragma mark - UIScrollView delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
  CGFloat pageWidth = scrollView.frame.size.width;
  if (scrollView.contentOffset.x > scrollView.contentSize.width - pageWidth) {
    [self reloadDaySummaries];
    return;
  }

  NSInteger pageIndex = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;

  __weak WASummaryViewController *wSelf = self;

  if (scrollView == self.summaryScrollView) {

    if (self.scrollingEventPage) {
      return;
    }

    if (self.currentDaySummary.summaryIndex != pageIndex) {

      self.currentDaySummary = self.daySummaries[@(pageIndex)];
      self.scrollingEventPage = YES;
      [UIView animateWithDuration:0.3 animations:^{
        [wSelf.eventScrollView setContentOffset:CGPointMake(wSelf.eventScrollView.frame.size.width*wSelf.currentDaySummary.eventIndex, 0)];
      } completion:^(BOOL finished) {
        wSelf.scrollingEventPage = NO;
      }];

    }
    
  } else {

    if (self.scrollingSummaryPage) {
      return;
    }

    if (self.currentDaySummary.eventIndex > pageIndex) {

      self.currentDaySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex-1)];
      self.scrollingSummaryPage = YES;
      [UIView animateWithDuration:0.3 animations:^{
        [wSelf.summaryScrollView setContentOffset:CGPointMake(wSelf.summaryScrollView.frame.size.width*wSelf.currentDaySummary.summaryIndex, 0)];
      } completion:^(BOOL finished) {
        wSelf.scrollingSummaryPage = NO;
      }];

    } else if (self.currentDaySummary.eventIndex + [self.currentDaySummary.eventPages count] <= pageIndex) {

      self.currentDaySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex+1)];
      self.scrollingSummaryPage = YES;
      [UIView animateWithDuration:0.3 animations:^{
        [wSelf.summaryScrollView setContentOffset:CGPointMake(wSelf.summaryScrollView.frame.size.width*wSelf.currentDaySummary.summaryIndex, 0)];
      } completion:^(BOOL finished) {
        wSelf.scrollingSummaryPage = NO;
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
