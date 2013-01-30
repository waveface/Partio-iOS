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

@implementation WADaySummary

- (id)initWithUser:(WAUser *)user date:(NSDate *)date context:(NSManagedObjectContext *)context {

  self = [super init];
  if (self) {
    NSFetchRequest *request = [[WADataStore defaultStore] newFetchRequestForArticlesOnDate:date];
    self.articles = [context executeFetchRequest:request error:nil];
    
    self.eventPages = [NSMutableArray array];
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
    
    self.summaryPage = [WASummaryPageView viewFromNib];
    self.summaryPage.user = user;
    self.summaryPage.date = date;
    self.summaryPage.numberOfEvents = [self.articles count];
    [self.summaryPage.photosButton addTarget:self action:@selector(handlePhotosButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.summaryPage.documentsButton addTarget:self action:@selector(handleDocumentsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.summaryPage.webpagesButton addTarget:self action:@selector(handleWebpagesButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

  }
  return self;

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
