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

@implementation WASummaryPageView

+ (WASummaryPageView *)viewFromNib {

  WASummaryPageView *view = [[[UINib nibWithNibName:@"WASummaryPageView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
//  self.photosButton.layer.borderColor = [UIColor whiteColor].CGColor;
//  self.photosButton.layer.borderWidth = 1.0;
//  self.photosButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
//  self.documentsButton.layer.borderColor = [UIColor whiteColor].CGColor;
//  self.documentsButton.layer.borderWidth = 1.0;
//  self.documentsButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
//  self.webpagesButton.layer.borderColor = [UIColor whiteColor].CGColor;
//  self.webpagesButton.layer.borderWidth = 1.0;
//  self.webpagesButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
  
  return view;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setDate:(NSDate *)date {

  _date = date;
  
  self.dayLabel.text = [date dayString];
  self.weekDayLabel.text = [date localizedWeekDayFullString];
  self.monthLabel.text = [date localizedMonthFullString];

}

- (void)setUser:(WAUser *)user {

  _user = user;

  self.helloLabel.text = [NSString stringWithFormat:NSLocalizedString(@"HELLO_NAME_TEXT", @"Hello text in summary view"), user.nickname];

}

- (void)setNumberOfEvents:(NSUInteger)numberOfEvents {

  _numberOfEvents = numberOfEvents;
  
  self.eventSummaryLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EVENT_SUMMARY_TEXT", @"Event summary text in summary view"), numberOfEvents];

}

@end
