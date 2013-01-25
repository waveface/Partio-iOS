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

@interface WASummaryViewController ()

@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) NSDate *beginningDate;
@property (nonatomic, strong) WADaySummary *currentDaySummary;
@property (nonatomic, strong) NSMutableDictionary *daySummaries;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL scrollingSummaryPage;
@property (nonatomic) BOOL scrollingEventPage;
@property (nonatomic) BOOL needsReload;

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

  WADaySummary *daySummary = [[WADaySummary alloc] initWithUser:self.user date:[self dayAtIndex:0] context:self.managedObjectContext];
  [self insertDaySummary:daySummary atIndex:0];
  self.currentDaySummary = daySummary;

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
  self.eventScrollView.contentSize = CGSizeMake(self.eventScrollView.frame.size.width * totalEventPagesCount, self.eventScrollView.frame.size.height);
  self.summaryScrollView.contentSize = CGSizeMake(self.summaryScrollView.frame.size.width * [self.daySummaries count], self.summaryScrollView.frame.size.height);

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

  NSInteger oldEventIndex = _currentDaySummary.eventIndex;

  _currentDaySummary = currentDaySummary;

  NSInteger pageControllIndex = 0;
  
  if (self.scrollingEventPage && oldEventIndex > _currentDaySummary.eventIndex) {
    pageControllIndex = [_currentDaySummary.articles count] - 1;
  }
  
  [self changeBackgroundImageWithDaySummary:currentDaySummary pageControllIndex:pageControllIndex];

  self.eventPageControll.numberOfPages = [currentDaySummary.articles count];
  self.eventPageControll.currentPage = pageControllIndex;

}

- (void)changeBackgroundImageWithDaySummary:(WADaySummary *)daySummary pageControllIndex:(NSInteger)pageControllIndex {

  if ([daySummary.articles count] > 0) {
    NSURL *articleURL = [[daySummary.articles[pageControllIndex] objectID] URIRepresentation];
    __weak WASummaryViewController *wSelf = self;
    __block NSManagedObjectContext *context = nil;
    __block WAArticle *article = nil;
    [[[self class] backgroundImageDisplayQueue] addOperationWithBlock:^{
      context = [[WADataStore defaultStore] disposableMOC];
      article = (WAArticle *)[context irManagedObjectForURI:articleURL];
      [article.representingFile irObserve:@"smallThumbnailFilePath" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
        if (wSelf.currentDaySummary != daySummary) {
	return;
        }
        if (wSelf.eventPageControll.currentPage != pageControllIndex) {
	return;
        }
        NSManagedObjectContext *contextKeeper = context;
        if (toValue) {
	UIImage *backgroundImage = [[UIImage imageWithData:[NSData dataWithContentsOfFile:toValue options:NSDataReadingMappedIfSafe error:nil]] stackBlur:5.0];
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
	  if (wSelf.currentDaySummary != daySummary) {
	    return;
	  }
	  if (wSelf.eventPageControll.currentPage != pageControllIndex) {
	    return;
	  }
	  [wSelf.backgroundImageView addCrossFadeAnimationWithTargetImage:backgroundImage];
	}];
        }
      }];
    }];
  } else {
    UIImage *backgroundImage = [[self class] sharedBackgroundImage];
    [self.backgroundImageView addCrossFadeAnimationWithTargetImage:backgroundImage];
  }

}

- (void)reloadDaySummaries {
  
  if (!self.daySummaries[@(self.currentDaySummary.summaryIndex+2)]) {
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
      for (NSInteger idx = 0; idx <= wSelf.currentDaySummary.summaryIndex+20; idx++) {
        if (idx >= 0) {
	if (!wSelf.daySummaries[@(idx)]) {
	  WADaySummary *daySummary = [[WADaySummary alloc] initWithUser:self.user date:[self dayAtIndex:idx] context:self.managedObjectContext];
	  [wSelf insertDaySummary:daySummary atIndex:idx];
	}
        }
      }
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
    daySummary.eventIndex = [self.daySummaries[@(idx-1)] eventIndex] + [[self.daySummaries[@(idx-1)] eventPages] count];
  } else if (idx < 0) {
    daySummary.eventIndex = [self.daySummaries[@(idx+1)] eventIndex] - [[self.daySummaries[@(idx)] eventPages] count];
  } else {
    daySummary.eventIndex = 0;
  }
  self.daySummaries[@(idx)] = daySummary;
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

+ (NSOperationQueue *)backgroundImageDisplayQueue {

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
        [wSelf.eventScrollView setContentOffset:CGPointMake(self.eventScrollView.frame.size.width*self.currentDaySummary.eventIndex, 0)];
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
        [wSelf.summaryScrollView setContentOffset:CGPointMake(self.summaryScrollView.frame.size.width*self.currentDaySummary.summaryIndex, 0)];
      } completion:^(BOOL finished) {
        wSelf.scrollingSummaryPage = NO;
        [wSelf reloadDaySummariesIfNeeded];
      }];

    } else if (self.currentDaySummary.eventIndex + [self.currentDaySummary.eventPages count] <= pageIndex) {

      self.currentDaySummary = self.daySummaries[@(self.currentDaySummary.summaryIndex+1)];
      [self reloadDaySummaries];
      self.scrollingSummaryPage = YES;
      [UIView animateWithDuration:0.3 animations:^{
        [wSelf.summaryScrollView setContentOffset:CGPointMake(self.summaryScrollView.frame.size.width*self.currentDaySummary.summaryIndex, 0)];
      } completion:^(BOOL finished) {
        wSelf.scrollingSummaryPage = NO;
        [wSelf reloadDaySummariesIfNeeded];
      }];

    } else if (self.eventPageControll.currentPage != pageIndex - self.currentDaySummary.eventIndex){
      
      self.eventPageControll.currentPage = pageIndex - self.currentDaySummary.eventIndex;
      [self changeBackgroundImageWithDaySummary:self.currentDaySummary pageControllIndex:self.eventPageControll.currentPage];

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
