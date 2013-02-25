//
//  WANewDaySummaryViewCell.m
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDaySummaryViewCell.h"
#import "WANewDaySummary.h"
#import "NSDate+WAAdditions.h"
#import "Foundation+IRAdditions.h"
#import "WAAppDelegate_iOS.h"
#import "WADayViewController.h"
#import "WASlidingMenuViewController.h"
#import "WAUser.h"

NSString *kWANewDaySummaryViewCellID = @"NewDaySummaryViewCell";

@implementation WANewDaySummaryViewCell

- (void)awakeFromNib {

  self.photosButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.photosButton.layer.borderWidth = 1.0;
  self.photosButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  [self.photosButton setImage:[[self class] sharedPhotosIconImage] forState:UIControlStateNormal];
  self.docsButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.docsButton.layer.borderWidth = 1.0;
  self.docsButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  [self.docsButton setImage:[[self class] sharedDocumentsIconImage] forState:UIControlStateNormal];
  self.websButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.websButton.layer.borderWidth = 1.0;
  self.websButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  [self.websButton setImage:[[self class] sharedWebIconImage] forState:UIControlStateNormal];

}

- (void)setRepresentingDaySummary:(WANewDaySummary *)representingDaySummary {

  NSParameterAssert([NSThread isMainThread]);

  _representingDaySummary = representingDaySummary;

  self.weekDayLabel.text = [representingDaySummary.date localizedWeekDayFullString];
  self.dayLabel.text = [representingDaySummary.date dayString];
  self.monthLabel.text = [representingDaySummary.date localizedMonthShortString];
  self.yearLabel.text = [representingDaySummary.date yearString];

  __weak WANewDaySummaryViewCell *wSelf = self;

  [representingDaySummary irObserve:@"numOfPhotos" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    if ([NSThread isMainThread]) {
      NSString *numOfPhotosString = [NSString stringWithFormat:@"%d", [toValue integerValue]];
      [wSelf.photosButton setTitle:numOfPhotosString forState:UIControlStateNormal];
      [wSelf.photosButton setTitle:numOfPhotosString forState:UIControlStateHighlighted];
    } else {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *numOfPhotosString = [NSString stringWithFormat:@"%d", [toValue integerValue]];
        [wSelf.photosButton setTitle:numOfPhotosString forState:UIControlStateNormal];
        [wSelf.photosButton setTitle:numOfPhotosString forState:UIControlStateHighlighted];
      }];
    }
  }];
  
  [representingDaySummary irObserve:@"numOfDocuments" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    if ([NSThread isMainThread]) {
      NSString *numOfDocsString = [NSString stringWithFormat:@"%d", [toValue integerValue]];
      [wSelf.docsButton setTitle:numOfDocsString forState:UIControlStateNormal];
      [wSelf.docsButton setTitle:numOfDocsString forState:UIControlStateHighlighted];
    } else {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *numOfDocsString = [NSString stringWithFormat:@"%d", [toValue integerValue]];
        [wSelf.docsButton setTitle:numOfDocsString forState:UIControlStateNormal];
        [wSelf.docsButton setTitle:numOfDocsString forState:UIControlStateHighlighted];
      }];
    }
  }];

  [representingDaySummary irObserve:@"numOfWebpages" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    if ([NSThread isMainThread]) {
      NSString *numOfWebsString = [NSString stringWithFormat:@"%d", [toValue integerValue]];
      [wSelf.websButton setTitle:numOfWebsString forState:UIControlStateNormal];
      [wSelf.websButton setTitle:numOfWebsString forState:UIControlStateHighlighted];
    } else {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *numOfWebsString = [NSString stringWithFormat:@"%d", [toValue integerValue]];
        [wSelf.websButton setTitle:numOfWebsString forState:UIControlStateNormal];
        [wSelf.websButton setTitle:numOfWebsString forState:UIControlStateHighlighted];
      }];
    }
  }];
  
  [representingDaySummary irObserve:@"numOfEvents" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    void (^setGreetingText)(void) = ^ {
      if (isSameDay(representingDaySummary.date, [NSDate date])) {
        if ([toValue integerValue] == 0) {
          wSelf.greetingLabel.text = NSLocalizedString(@"GREETING_TEXT_NO_EVENTS_TODAY", @"greeting text of day summary view");
        } else {
          wSelf.greetingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"GREETING_TEXT_WITH_EVENTS_TODAY", @"greeting text of day summary view"), representingDaySummary.user.nickname];
        }
      } else {
        if ([toValue integerValue] == 0) {
          wSelf.greetingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"GREETING_TEXT_NO_EVENTS_PAST", @"greeting text of day summary view"), representingDaySummary.user.nickname];
        } else {
          wSelf.greetingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"GREETING_TEXT_WITH_EVENTS_PAST", @"greeting text of day summary view"), [toValue integerValue]];
        }
      }
    };
    if ([NSThread isMainThread]) {
      setGreetingText();
    } else {
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        setGreetingText();
      }];
    }
  }];

}

- (void)prepareForReuse {

  [self.photosButton setTitle:@"" forState:UIControlStateNormal];
  [self.photosButton setTitle:@"" forState:UIControlStateHighlighted];
  [self.docsButton setTitle:@"" forState:UIControlStateNormal];
  [self.docsButton setTitle:@"" forState:UIControlStateHighlighted];
  [self.websButton setTitle:@"" forState:UIControlStateNormal];
  [self.websButton setTitle:@"" forState:UIControlStateHighlighted];
  self.greetingLabel.text = @"";

  [self.representingDaySummary irRemoveObserverBlocksForKeyPath:@"numOfPhotos"];
  [self.representingDaySummary irRemoveObserverBlocksForKeyPath:@"numOfDocuments"];
  [self.representingDaySummary irRemoveObserverBlocksForKeyPath:@"numOfWebpages"];
  [self.representingDaySummary irRemoveObserverBlocksForKeyPath:@"numOfEvents"];

}

- (void)dealloc {
  
  [self.representingDaySummary irRemoveObserverBlocksForKeyPath:@"numOfPhotos"];
  [self.representingDaySummary irRemoveObserverBlocksForKeyPath:@"numOfDocuments"];
  [self.representingDaySummary irRemoveObserverBlocksForKeyPath:@"numOfWebpages"];
  [self.representingDaySummary irRemoveObserverBlocksForKeyPath:@"numOfEvents"];

}

+ (UIImage *)sharedPhotosIconImage {
  
  static UIImage *photosIcon;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    photosIcon = [UIImage imageNamed:@"PhotosIcon"];
  });
  return photosIcon;
  
}

+ (UIImage *)sharedDocumentsIconImage {
  
  static UIImage *documentsIcon;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    documentsIcon = [UIImage imageNamed:@"DocumentsIcon"];
  });
  return documentsIcon;
  
}

+ (UIImage *)sharedWebIconImage {
  
  static UIImage *webIcon;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    webIcon = [UIImage imageNamed:@"WebIcon"];
  });
  return webIcon;
  
}

#pragma mark - Target actions

- (IBAction)handlePhotosButtonPressed:(id)sender {
  
  __weak WANewDaySummaryViewCell *wSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
    [appDelegate.slidingMenu switchToViewStyle:WAPhotosViewStyle onDate:wSelf.representingDaySummary.date];
  }];
  
}

- (IBAction)handleDocsButtonPressed:(id)sender {

  __weak WANewDaySummaryViewCell *wSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
    [appDelegate.slidingMenu switchToViewStyle:WADocumentsViewStyle onDate:wSelf.representingDaySummary.date];
  }];

}

- (IBAction)handleWebsButtonPressed:(id)sender {

  __weak WANewDaySummaryViewCell *wSelf = self;
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
    [appDelegate.slidingMenu switchToViewStyle:WAWebpagesViewStyle onDate:wSelf.representingDaySummary.date];
  }];

}

@end
