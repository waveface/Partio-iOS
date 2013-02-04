//
//  WASummaryPageView.m
//  wammer
//
//  Created by kchiu on 13/1/23.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASummaryPageView.h"
#import "NSDate+WAAdditions.h"
#import "WAUser.h"

static NSString * kWASummaryPageViewKVOContext = @"WASummaryPageViewKVOContext";

@implementation WASummaryPageView

+ (WASummaryPageView *)viewFromNib {

  WASummaryPageView *view = [[[UINib nibWithNibName:@"WASummaryPageView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
  
  return view;
}

- (void)awakeFromNib {

  self.photosButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.photosButton.layer.borderWidth = 1.0;
  self.photosButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  self.documentsButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.documentsButton.layer.borderWidth = 1.0;
  self.documentsButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  self.webpagesButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.webpagesButton.layer.borderWidth = 1.0;
  self.webpagesButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];

}

- (void)setDate:(NSDate *)date {

  NSParameterAssert([NSThread isMainThread]);

  _date = date;
  
  self.dayLabel.text = [date dayString];
  self.weekDayLabel.text = [date localizedWeekDayFullString];
  self.monthLabel.text = [date localizedMonthShortString];
  self.yearLabel.text = [date yearString];

}

- (void)setUser:(WAUser *)user {

  NSParameterAssert([NSThread isMainThread]);

  _user = user;

  __weak WASummaryPageView *wSelf = self;
  [_user irObserve:@"nickname" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:&kWASummaryPageViewKVOContext withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    if (toValue) {
      wSelf.helloLabel.text = [NSString stringWithFormat:NSLocalizedString(@"HELLO_NAME_TEXT", @"Hello text in summary view"), toValue];
    } else {
      wSelf.helloLabel.text = [NSString stringWithFormat:NSLocalizedString(@"HELLO_NAME_TEXT", @"Hello text in summary view"), @""];
    }
  }];

}

- (void)setNumberOfEvents:(NSUInteger)numberOfEvents {

  NSParameterAssert([NSThread isMainThread]);

  _numberOfEvents = numberOfEvents;
  
  self.eventSummaryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EVENT_SUMMARY_TEXT", @"Event summary text in summary view"), numberOfEvents];

}

- (void)setNumberOfPhotos:(NSUInteger)numberOfPhotos {

  NSParameterAssert([NSThread isMainThread]);

  _numberOfPhotos = numberOfPhotos;
  
  [self.photosButton setTitle:[NSString stringWithFormat:@"%d", numberOfPhotos]
		 forState:UIControlStateNormal];
  [self.photosButton setTitle:[NSString stringWithFormat:@"%d", numberOfPhotos]
		 forState:UIControlStateHighlighted];

}

- (void)setNumberOfDocuments:(NSUInteger)numberOfDocuments {

  NSParameterAssert([NSThread isMainThread]);

  _numberOfDocuments = numberOfDocuments;
  
  [self.documentsButton setTitle:[NSString stringWithFormat:@"%d", numberOfDocuments]
		    forState:UIControlStateNormal];
  [self.documentsButton setTitle:[NSString stringWithFormat:@"%d", numberOfDocuments]
		    forState:UIControlStateHighlighted];

}

- (void)setNumberOfWebpages:(NSUInteger)numberOfWebpages {

  NSParameterAssert([NSThread isMainThread]);

  _numberOfWebpages = numberOfWebpages;
  
  [self.webpagesButton setTitle:[NSString stringWithFormat:@"%d", numberOfWebpages]
		   forState:UIControlStateNormal];
  [self.webpagesButton setTitle:[NSString stringWithFormat:@"%d", numberOfWebpages]
		   forState:UIControlStateHighlighted];

}

- (void)dealloc {

  [_user irRemoveObserverBlocksForKeyPath:@"nickname" context:&kWASummaryPageViewKVOContext];

}

@end
