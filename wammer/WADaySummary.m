//
//  WAOneDaySummary.m
//  wammer
//
//  Created by kchiu on 13/1/23.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WADaySummary.h"
#import "WADataStore.h"
#import "WAEventPageView.h"
#import "WASummaryPageView.h"
#import "WAEventViewController.h"
#import "WANavigationController.h"
#import "WAEventDescriptionView.h"
#import "WAAppDelegate_iOS.h"
#import "WADayViewController.h"
#import "WASlidingMenuViewController.h"
#import "WAPhotoStreamViewController.h"
#import "WADocumentStreamViewController.h"
#import "WAWebStreamViewController.h"
#import "WAFileAccessLog.h"

@interface WADaySummary ()

@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation WADaySummary

- (id)initWithUser:(WAUser *)user date:(NSDate *)date context:(NSManagedObjectContext *)context {

  self = [super init];
  if (self) {
    self.user = user;
    self.date = date;
    self.managedObjectContext = context;
    self.eventPages = [NSMutableArray array];
    [self configureSummaryAndEventPages];
  }
  return self;

}

- (void)configureSummaryAndEventPages {

  NSFetchRequest *articlesFetchRequest = [[WADataStore defaultStore] newFetchRequestForArticlesOnDate:self.date];
  self.articles = [self.managedObjectContext executeFetchRequest:articlesFetchRequest error:nil];
  if ([self.eventPages count] == 0) {
    // initialization
    if ([self.articles count] == 0) {
      WAEventPageView *eventPageView = [WAEventPageView viewWithRepresentingArticle:nil];
      [self.eventPages addObject:eventPageView];
    } else {
      for (WAArticle *article in self.articles) {
        WAEventPageView *eventPageView = [WAEventPageView viewWithRepresentingArticle:article];
        [eventPageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEventPagePressed:)]];
        [self.eventPages addObject:eventPageView];
      }
    }
  } else {
    // update
    if ([self.articles count] == 0) {
      // NO OP
    } else {

      UIView *eventSuperView = [self.eventPages[0] superview];

      // remove empty event page
      if ([self.eventPages count] == 1 && ![self.eventPages[0] representingArticle]) {
        [self.eventPages[0] removeFromSuperview];
        [self.eventPages removeAllObjects];
      }

      // insert event pages for new articles which are not existing in current event pages
      for (WAArticle *article in self.articles) {
        __block BOOL found = NO;
        __block NSUInteger foundIndex = 0;
        [self.eventPages enumerateObjectsUsingBlock:^(WAEventPageView *eventPage, NSUInteger idx, BOOL *stop) {
	if ([article.identifier isEqualToString:eventPage.representingArticle.identifier]) {
	  found = YES;
	  foundIndex = idx;
	  *stop = YES;
	}
	if ([article.eventStartDate compare:eventPage.representingArticle.eventStartDate] == NSOrderedDescending) {
	  *stop = YES;
	}
        }];
        if (found) {
	NSUInteger imageViewsCount = [[self.eventPages[foundIndex] imageViews] count];
	if ([article.files count] != imageViewsCount && imageViewsCount < 4) {
	  // if articles has more or less photos to display, then replace the event page with a new one
	  [self.eventPages[foundIndex] removeFromSuperview];
	  [self.eventPages removeObjectAtIndex:foundIndex];
	  WAEventPageView *eventPageView = [WAEventPageView viewWithRepresentingArticle:article];
	  [eventPageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEventPagePressed:)]];
	  [eventSuperView addSubview:eventPageView];
	  [self.eventPages insertObject:eventPageView atIndex:foundIndex];
	}
        } else {
	WAEventPageView *eventPageView = [WAEventPageView viewWithRepresentingArticle:article];
	[eventPageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEventPagePressed:)]];
	[eventSuperView addSubview:eventPageView];
	[self.eventPages insertObject:eventPageView atIndex:foundIndex];
        }
      }
    }
  }
  
  if (!self.summaryPage) {
    self.summaryPage = [WASummaryPageView viewFromNib];
    [self.summaryPage.photosButton addTarget:self action:@selector(handlePhotosButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.summaryPage.documentsButton addTarget:self action:@selector(handleDocumentsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.summaryPage.webpagesButton addTarget:self action:@selector(handleWebpagesButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.summaryPage.user = self.user;
    self.summaryPage.date = self.date;
  }
  self.summaryPage.numberOfEvents = [self.articles count];
  
  NSFetchRequest *photosFetchRequest = [WAPhotoStreamViewController fetchRequestForPhotosOnDate:self.date];
  self.summaryPage.numberOfPhotos = [self.managedObjectContext countForFetchRequest:photosFetchRequest error:nil];
  
  NSFetchRequest *documentAccessLogsFetchRequest = [WADocumentStreamViewController fetchRequestForFileAccessLogsOnDate:self.date];
  NSArray *documentAccessLogs = [self.managedObjectContext executeFetchRequest:documentAccessLogsFetchRequest error:nil];
  NSMutableSet *documentFilePathSet = [NSMutableSet set];
  for (WAFileAccessLog *accessLog in documentAccessLogs) {
    [documentFilePathSet addObject:accessLog.filePath];
  }
  self.summaryPage.numberOfDocuments = [documentFilePathSet count];
  
  NSFetchRequest *webpageAccessLogsFetchRequest = [WAWebStreamViewController fetchRequestForWebpageAccessLogsOnDate:self.date];
  NSArray *webpageAccessLogs = [self.managedObjectContext executeFetchRequest:webpageAccessLogsFetchRequest error:nil];
  NSMutableSet *webpageFileIdentifierSet = [NSMutableSet set];
  for (WAFileAccessLog *accessLog in webpageAccessLogs) {
    [webpageFileIdentifierSet addObject:accessLog.file.identifier];
  }
  self.summaryPage.numberOfWebpages = [webpageFileIdentifierSet count];

}

#pragma mark - Target actions

- (void)handleEventPagePressed:(UIGestureRecognizer *)sender {

  WAEventPageView *eventPage = (WAEventPageView *)sender.view;
  eventPage.descriptionView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.5];
  NSURL *articleURL = [[eventPage.representingArticle objectID] URIRepresentation];
  __weak WADaySummary *wSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    WAEventViewController *eventVC = [WAEventViewController controllerForArticleURL:articleURL];
    eventVC.completion = ^ {
      eventPage.descriptionView.backgroundColor = [UIColor clearColor];
    };
    WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:eventVC];
    [wSelf.delegate presentViewController:navVC animated:YES completion:nil];
  }];

}

- (void)handlePhotosButtonPressed:(id)sender {

  __weak WADaySummary *wSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
    [appDelegate.slidingMenu switchToViewStyle:WAPhotosViewStyle onDate:wSelf.summaryPage.date];
  }];

}

- (void)handleDocumentsButtonPressed:(id)sender {

  __weak WADaySummary *wSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
    [appDelegate.slidingMenu switchToViewStyle:WADocumentsViewStyle onDate:wSelf.summaryPage.date];
  }];

}

- (void)handleWebpagesButtonPressed:(id)sender {

  __weak WADaySummary *wSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
    [appDelegate.slidingMenu switchToViewStyle:WAWebpagesViewStyle onDate:wSelf.summaryPage.date];
  }];

}

@end
