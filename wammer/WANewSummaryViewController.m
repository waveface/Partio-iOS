//
//  WANewSummaryViewController.m
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewSummaryViewController.h"
#import "WANewSummaryDataSource.h"
#import "NSDate+WAAdditions.h"
#import "WANewDaySummaryViewCell.h"
#import "WANewDayEventViewCell.h"
#import "WADayViewController.h"
#import "IIViewDeckController.h"
#import "IRBarButtonItem.h"
#import "UIImageView+WAAdditions.h"
#import "WANewDaySummary.h"
#import "WANewDayEvent.h"
#import "WAOverlayBezel.h"
#import "WAArticle.h"
#import "WAEventViewController.h"
#import "WANavigationController.h"
#import "WAContextMenuViewController.h"
#import "WACalendarPopupViewController_phone.h"
#import "WAAppDelegate_iOS.h"

@interface WANewSummaryViewController ()

@property (nonatomic, strong) WANewSummaryDataSource *dataSource;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) WANewDayEvent *currentDayEvent;
@property (nonatomic, strong) WANewDaySummary *currentDaySummary;
@property (nonatomic) NSUInteger summaryPageIndex;
@property (nonatomic) NSUInteger eventPageIndex;
@property (nonatomic) BOOL contextMenuOpened;
@property (nonatomic) BOOL reloadingPreviousDays;
@property (nonatomic) BOOL reloadingFollowingDays;
@property (nonatomic, strong) WAOverlayBezel *reloadingBezel;
@property (nonatomic) WADayViewSupportedStyle presentingStyle;

@end

@implementation WANewSummaryViewController

- (void)viewDidLoad {

  [super viewDidLoad];

  self.presentingStyle = WAEventsViewStyle;
  
  self.backgroundImageView.clipsToBounds = YES;
  
  __weak WANewSummaryViewController *wSelf = self;
  self.navigationItem.leftBarButtonItem = WABarButtonItem([UIImage imageNamed:@"menuWhite"], @"", ^{
    [wSelf.viewDeckController toggleLeftView];
  });
  self.navigationItem.rightBarButtonItem = WABarButtonItem([UIImage imageNamed:@"Cal"], @"", ^{
    [wSelf calButtonPressed];
  });
  
  UIColor *naviBgColor = [[UIColor clearColor] colorWithAlphaComponent:0];
  UIGraphicsBeginImageContext(self.navigationController.navigationBar.frame.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, naviBgColor.CGColor);
  CGContextAddRect(context, self.navigationController.navigationBar.frame);
  CGContextFillPath(context);
  UIImage *naviBg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  [self.navigationController.navigationBar setBackgroundImage:naviBg forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.translucent = YES;

  self.navigationItem.titleView = [WAContextMenuViewController titleViewForContextMenu:self.presentingStyle
							 performSelector:@selector(contextMenuTapped)
							      withObject:self];

  self.dataSource = [[WANewSummaryDataSource alloc] initWithDate:[[NSDate date] dayBegin]];
  self.dataSource.summaryCollectionView = self.summaryCollectionView;
  self.dataSource.eventCollectionView = self.eventCollectionView;
  self.dataSource.delegate = self;
  
  self.summaryCollectionView.dataSource = self.dataSource;
  self.summaryCollectionView.delegate = self;
  self.eventCollectionView.dataSource = self.dataSource;
  self.eventCollectionView.delegate = self;

  self.summaryCollectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
  self.eventCollectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
  self.eventPageControl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];

  self.currentDaySummary = [self.dataSource daySummaryAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  self.eventPageControl.numberOfPages = self.currentDaySummary.numOfEvents;
  [self.currentDaySummary irObserve:@"numOfEvents" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      wSelf.eventPageControl.numberOfPages = [toValue integerValue];
    }];
  }];
  
  self.currentDayEvent = [self.dataSource dayEventAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  [self.backgroundImageView addCrossFadeAnimationWithTargetImage:self.currentDayEvent.backgroundImage];
  [self.currentDayEvent irObserve:@"backgroundImage" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [wSelf.backgroundImageView addCrossFadeAnimationWithTargetImage:toValue];
    }];
  }];

}

- (void)viewDidAppear:(BOOL)animated {

  [super viewDidAppear:animated];
  
  // load 20 future days if possible
  NSDate *date = self.currentDaySummary.date;
  if ([self.dataSource loadMoreDays:20 since:date]) {
    [self.summaryCollectionView reloadData];
    [self.eventCollectionView reloadData];
    NSIndexPath *daySummaryIndex = [self.dataSource indexPathOfDaySummaryOnDate:date];
    NSIndexPath *dayEventIndex = [self.dataSource indexPathOfFirstDayEventOnDate:date];
    [self scrollToDaySummaryAtIndexPath:daySummaryIndex animated:NO];
    [self scrollToDayEventAtIndexPath:dayEventIndex animated:NO];
  }

}

- (void)dealloc {
  
  [self.currentDaySummary irRemoveObserverBlocksForKeyPath:@"numOfEvents"];
  [self.currentDayEvent irRemoveObserverBlocksForKeyPath:@"backgroundImage"];
  self.dataSource.delegate = nil;
  
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

- (void)setCurrentDaySummary:(WANewDaySummary *)currentDaySummary {
  
  [_currentDaySummary irRemoveObserverBlocksForKeyPath:@"numOfEvents"];

  _currentDaySummary = currentDaySummary;

  self.eventPageControl.numberOfPages = _currentDaySummary.numOfEvents;
  
  __weak WANewSummaryViewController *wSelf = self;
  [_currentDaySummary irObserve:@"numOfEvents" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      wSelf.eventPageControl.numberOfPages = [toValue integerValue];
    }];
  }];
  [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Summary" withAction:@"Show" withLabel:@"Event" withValue:@(_currentDaySummary.numOfEvents)];
  
}

- (void)setCurrentDayEvent:(WANewDayEvent *)currentDayEvent {

  [_currentDayEvent irRemoveObserverBlocksForKeyPath:@"backgroundImage"];

  _currentDayEvent = currentDayEvent;

  [self.backgroundImageView addCrossFadeAnimationWithTargetImage:_currentDayEvent.backgroundImage];

  __weak WANewSummaryViewController *wSelf = self;
  [_currentDayEvent irObserve:@"backgroundImage" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [wSelf.backgroundImageView addCrossFadeAnimationWithTargetImage:toValue];
    }];
  }];

}

- (void)scrollToDaySummaryAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
  
  if (animated) {
    [self.summaryCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
  } else {
    [self.summaryCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
  }

  self.summaryPageIndex = indexPath.item;

}

- (void)scrollToDayEventAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {

  if (animated) {
    [self.eventCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
  } else {
    [self.eventCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
  }

  self.eventPageIndex = indexPath.item;

}

#pragma mark - WANewSummaryDataSource delegates

- (void)refreshViews {
  
  [self.summaryCollectionView reloadData];
  [self.eventCollectionView reloadData];
  NSIndexPath *daySummaryIndexPath = [self.dataSource indexPathOfDaySummaryOnDate:self.currentDaySummary.date];
  NSIndexPath *dayEventIndexPath = [self.dataSource indexPathOfDayEvent:self.currentDayEvent];
  self.currentDayEvent = [self.dataSource dayEventAtIndexPath:dayEventIndexPath]; // update current day event
  [self scrollToDaySummaryAtIndexPath:daySummaryIndexPath animated:NO];
  [self scrollToDayEventAtIndexPath:dayEventIndexPath animated:NO];

}

#pragma mark - Target actions

- (void)calButtonPressed {
  
  if (isPad()) {
    
    // NO OP
    
  } else {
    
    __block WACalendarPopupViewController_phone *calendarPopup = [[WACalendarPopupViewController_phone alloc] initWithDate:self.currentDaySummary.date viewStyle:WAEventsViewStyle completion:^{
      
      [calendarPopup willMoveToParentViewController:nil];
      [calendarPopup removeFromParentViewController];
      [calendarPopup.view removeFromSuperview];
      [calendarPopup didMoveToParentViewController:nil];
      calendarPopup = nil;
      
    }];
    
    [self.viewDeckController addChildViewController:calendarPopup];
    [self.viewDeckController.view addSubview:calendarPopup.view];
    
  }
  
}

- (void)contextMenuTapped {
  
  __weak WANewSummaryViewController *wSelf = self;
  
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

#pragma mark - UICollectionView delegates

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

  if (collectionView == self.eventCollectionView) {
    WANewDayEventViewCell *cell = (WANewDayEventViewCell*)[self.eventCollectionView cellForItemAtIndexPath:indexPath];
    if (cell.representingDayEvent.style != WADayEventStyleNone) {
      WAArticle *article = cell.representingDayEvent.representingArticle;
      NSURL *articleURL = [[article objectID] URIRepresentation];
      __weak WANewSummaryViewController *wSelf = self;
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        WAEventViewController *eventVC = [WAEventViewController controllerForArticleURL:articleURL];
        WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:eventVC];
        [wSelf presentViewController:navVC animated:YES completion:nil];
      }];
    }
  }

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

  if (!scrollView.dragging && !scrollView.decelerating && !scrollView.tracking) {
    return;
  }
  
  if (self.reloadingPreviousDays || self.reloadingFollowingDays) {
    return;
  }

  CGFloat pageWidth = scrollView.frame.size.width;
  if (scrollView.contentOffset.x > scrollView.contentSize.width - pageWidth) {
    self.reloadingPreviousDays = YES;
    self.reloadingBezel = [[WAOverlayBezel alloc] initWithStyle:WAActivityIndicatorBezelStyle];
    [self.reloadingBezel show];
    return;
  }

  if (scrollView.contentOffset.x < 0) {
    if (isSameDay(self.currentDaySummary.date, [NSDate date])) {
      // no need to load future days
      return;
    }
    self.reloadingFollowingDays = YES;
    self.reloadingBezel = [[WAOverlayBezel alloc] initWithStyle:WAActivityIndicatorBezelStyle];
    [self.reloadingBezel show];
    return;
  }
  
  NSInteger pageIndex = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
  
  if (scrollView == self.summaryCollectionView) {

    if (self.summaryPageIndex != pageIndex) {
      
      self.summaryPageIndex = pageIndex;

      self.currentDaySummary = [self.dataSource daySummaryAtIndexPath:[NSIndexPath indexPathForItem:self.summaryPageIndex inSection:0]];

      NSIndexPath *eventIndexPath = [self.dataSource indexPathOfFirstDayEventOnDate:self.currentDaySummary.date];
      self.currentDayEvent = [self.dataSource dayEventAtIndexPath:eventIndexPath];

      [self scrollToDayEventAtIndexPath:eventIndexPath animated:YES];

      self.eventPageControl.currentPage = 0;

    }
    
  } else {
    
    if (self.eventPageIndex != pageIndex) {
      
      self.eventPageControl.currentPage += (pageIndex-self.eventPageIndex);
      self.eventPageIndex = pageIndex;
      
      self.currentDayEvent = [self.dataSource dayEventAtIndexPath:[NSIndexPath indexPathForItem:self.eventPageIndex inSection:0]];

      NSDate *eventDate = [self.dataSource dateOfDayEventAtIndexPath:[NSIndexPath indexPathForItem:self.eventPageIndex inSection:0]];
      NSDate *summaryDate = [self.dataSource dateOfDaySummaryAtIndexPath:[NSIndexPath indexPathForItem:self.summaryPageIndex inSection:0]];

      if ([eventDate compare:summaryDate] != NSOrderedSame) {
        
        NSIndexPath *summaryIndexPath = [self.dataSource indexPathOfDaySummaryOnDate:eventDate];
        self.currentDaySummary = [self.dataSource daySummaryAtIndexPath:summaryIndexPath];

        [self scrollToDaySummaryAtIndexPath:summaryIndexPath animated:YES];
        
        if ([eventDate compare:summaryDate] == NSOrderedAscending) {
          self.eventPageControl.currentPage = 0;
        } else {
          self.eventPageControl.currentPage = self.eventPageControl.numberOfPages-1;
        }
        
      }      

    }

  }

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  
  __weak WANewSummaryViewController *wSelf = self;
  
  if (self.reloadingPreviousDays) {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

      [wSelf.dataSource loadMoreDays:20 since:wSelf.currentDaySummary.date];
      
      [wSelf.summaryCollectionView reloadData];
      [wSelf.eventCollectionView reloadData];
      
      NSDate *previousDay = [wSelf.currentDaySummary.date dateOfPreviousDay];
      
      NSIndexPath *daySummaryIndexPath = [wSelf.dataSource indexPathOfDaySummaryOnDate:previousDay];
      wSelf.currentDaySummary = [wSelf.dataSource daySummaryAtIndexPath:daySummaryIndexPath];
      [wSelf scrollToDaySummaryAtIndexPath:daySummaryIndexPath animated:YES];
      
      NSIndexPath *dayEventIndexPath = [wSelf.dataSource indexPathOfFirstDayEventOnDate:previousDay];
      wSelf.currentDayEvent = [wSelf.dataSource dayEventAtIndexPath:dayEventIndexPath];
      [wSelf scrollToDayEventAtIndexPath:dayEventIndexPath animated:YES];
      
      [wSelf.reloadingBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
      wSelf.reloadingBezel = nil;
      
      wSelf.reloadingPreviousDays = NO;

    }];
    
  } else if (self.reloadingFollowingDays) {

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

      [wSelf.dataSource loadMoreDays:20 since:wSelf.currentDaySummary.date];
      
      [wSelf.summaryCollectionView reloadData];
      [wSelf.eventCollectionView reloadData];
      
      NSIndexPath *daySummaryIndexPath = [wSelf.dataSource indexPathOfDaySummaryOnDate:wSelf.currentDaySummary.date];
      [wSelf scrollToDaySummaryAtIndexPath:daySummaryIndexPath animated:NO];
      NSIndexPath *dayEventIndexPath = [wSelf.dataSource indexPathOfFirstDayEventOnDate:wSelf.currentDaySummary.date];
      [wSelf scrollToDayEventAtIndexPath:dayEventIndexPath animated:NO];
      
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        NSDate *followingDay = [wSelf.currentDaySummary.date dateOfFollowingDay];
        
        NSIndexPath *daySummaryIndexPath = [wSelf.dataSource indexPathOfDaySummaryOnDate:followingDay];
        wSelf.currentDaySummary = [wSelf.dataSource daySummaryAtIndexPath:daySummaryIndexPath];
        [wSelf scrollToDaySummaryAtIndexPath:daySummaryIndexPath animated:YES];
        
        if (scrollView == wSelf.summaryCollectionView) {
          NSIndexPath *dayEventIndexPath = [wSelf.dataSource indexPathOfFirstDayEventOnDate:followingDay];
          wSelf.currentDayEvent = [wSelf.dataSource dayEventAtIndexPath:dayEventIndexPath];
          [wSelf scrollToDayEventAtIndexPath:dayEventIndexPath animated:YES];
        } else {
          NSIndexPath *dayEventIndexPath = [wSelf.dataSource indexPathOfLastDayEventOnDate:followingDay];
          wSelf.currentDayEvent = [wSelf.dataSource dayEventAtIndexPath:dayEventIndexPath];
          [wSelf scrollToDayEventAtIndexPath:dayEventIndexPath animated:YES];
        }
        
        [wSelf.reloadingBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
        wSelf.reloadingBezel = nil;
        
        wSelf.reloadingFollowingDays = NO;
        
      }];

    }];

  }

}

#pragma mark - UICollectionView FlowLayout delegates

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

  if (collectionView == self.summaryCollectionView) {
    return self.summaryCollectionView.frame.size;
  } else if (collectionView == self.eventCollectionView) {
    return CGSizeMake(298, 148);
  } else {
    NSAssert(NO, @"unexpected collection view %@", collectionView);
    return CGSizeZero;
  }

}

#pragma mark - Context menu delegates

- (void) contextMenuItemDidSelect:(WADayViewSupportedStyle)itemStyle {
  
  WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
  [appDelegate.slidingMenu switchToViewStyle:itemStyle onDate:self.currentDaySummary.date];
  
}

#pragma mark - WADaysControlling delegates

- (BOOL)jumpToDate:(NSDate *)date animated:(BOOL)animated {
  
  self.dataSource = [[WANewSummaryDataSource alloc] initWithDate:date];
  self.dataSource.summaryCollectionView = self.summaryCollectionView;
  self.dataSource.eventCollectionView = self.eventCollectionView;
  self.dataSource.delegate = self;
  self.summaryCollectionView.dataSource = self.dataSource;
  self.eventCollectionView.dataSource = self.dataSource;

  self.currentDaySummary = [self.dataSource daySummaryAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  self.currentDayEvent = [self.dataSource dayEventAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

  [self.summaryCollectionView reloadData];
  [self.eventCollectionView reloadData];

  return YES;
  
}

- (void)jumpToRecentDay {

  [self jumpToDate:[[NSDate date] dayBegin] animated:NO];

}

@end
