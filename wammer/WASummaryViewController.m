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

@interface WASummaryViewController ()

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSArray *articles;
@property (nonatomic, strong) NSMutableArray *eventPages;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL pageControlUsed;

@end

@implementation WASummaryViewController

- (id)initWithDate:(NSDate *)date {

  self = [super init];
  if (self) {
    self.date = date;
    self.wantsFullScreenLayout = YES;
    self.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  }
  return self;

}

- (void)viewDidLoad {

  [super viewDidLoad];

  self.backgroundImageView.clipsToBounds = YES;
  self.photosButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.photosButton.layer.borderWidth = 1.0;
  self.photosButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  self.documentsButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.documentsButton.layer.borderWidth = 1.0;
  self.documentsButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  self.webpagesButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.webpagesButton.layer.borderWidth = 1.0;
  self.webpagesButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  self.dayLabel.text = [self.date dayString];
  self.weekDayLabel.text = [self.date localizedWeekDayFullString];
  self.monthLabel.text = [self.date localizedMonthFullString];

  WAUser *user = [[WADataStore defaultStore] mainUserInContext:self.managedObjectContext];
  self.helloLabel.text = [NSString stringWithFormat:NSLocalizedString(@"HELLO_NAME_TEXT", @"Hello text in summary view"), user.nickname];
  
  NSFetchRequest *request = [[WADataStore defaultStore] newFetchRequestForArticlesOnDate:self.date];
  self.articles = [self.managedObjectContext executeFetchRequest:request error:nil];
  self.eventSummaryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EVENT_SUMMARY_TEXT", @"Event summary text in summary view"), [self.articles count]];
  self.eventPageControll.numberOfPages = [self.articles count];
  self.eventPageControll.currentPage = 0;

  self.eventPages = [NSMutableArray array];
  for (WAArticle *article in self.articles) {
    WAEventPageView *eventPageView = [WAEventPageView viewWithRepresentingArticle:article];
    [self.eventPages addObject:eventPageView];
  }
  for (UIView *page in self.eventPages) {
    [self.eventScrollView addSubview:page];
  }
  self.eventScrollView.delegate = self;
  
  if ([self.articles count] > 0) {
    WAArticle *article = self.articles[0];
    __weak WASummaryViewController *wSelf = self;
    [article.representingFile irObserve:@"smallThumbnailImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
      if (toValue) {
        wSelf.backgroundImageView.image = [toValue stackBlur:5.0];
      }
    }];
  }

}

- (void)viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];
  
  __weak WASummaryViewController *wSelf = self;
  [self.eventPages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CGRect frame = wSelf.eventScrollView.frame;
    frame.origin.x = frame.size.width * idx;
    frame.origin.y = 0;
    WAEventPageView *view = obj;
    view.frame = frame;
  }];
  
}

- (void)viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];
  
  // Set scrollView's contentSize only works here if auto-layout is enabled
  // Ref: http://stackoverflow.com/questions/12619786/embed-imageview-in-scrollview-with-auto-layout-on-ios-6
  self.eventScrollView.contentSize = CGSizeMake(self.eventScrollView.frame.size.width * [self.eventPages count], self.eventScrollView.frame.size.height);
  
}

#pragma mark UIScrollView delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  
  if (self.pageControlUsed) {
    return;
  }
  
  CGFloat pageWidth = scrollView.frame.size.width;
  NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
  if (self.eventPageControll.currentPage != page) {
    WAArticle *article = self.articles[page];
    __weak WASummaryViewController *wSelf = self;
    [article.representingFile irObserve:@"smallThumbnailImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
      if (toValue) {
        wSelf.backgroundImageView.image = [toValue stackBlur:5.0];
      }
    }];
  }
  self.eventPageControll.currentPage = page;
  
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  
  self.pageControlUsed = NO;
  
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  
  self.pageControlUsed = NO;
  
}

@end
