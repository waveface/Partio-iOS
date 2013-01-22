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

@interface WASummaryViewController ()

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) WAArticle *article;

@end

@implementation WASummaryViewController

- (id)initWithDate:(NSDate *)date {

  self = [super init];
  if (self) {
    self.date = date;
    self.wantsFullScreenLayout = YES;
  }
  return self;

}

- (void)viewDidLoad {

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

  NSFetchRequest *request = [[WADataStore defaultStore] newFetchRequestForArticlesOnDate:self.date];
  NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  NSArray *articles = [context executeFetchRequest:request error:nil];
  if ([articles count] > 0) {
    self.article = articles[0];
    __weak WASummaryViewController *wSelf = self;
    [self.article.representingFile irObserve:@"smallThumbnailImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
      if (toValue) {
        wSelf.backgroundImageView.image = [toValue stackBlur:5.0];
      }
    }];
  }
  
}

@end
