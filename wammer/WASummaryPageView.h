//
//  WASummaryPageView.h
//  wammer
//
//  Created by kchiu on 13/1/23.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WAUser;
@interface WASummaryPageView : UIView

@property (weak, nonatomic) IBOutlet UIButton *photosButton;
@property (weak, nonatomic) IBOutlet UIButton *documentsButton;
@property (weak, nonatomic) IBOutlet UIButton *webpagesButton;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *weekDayLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *helloLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventSummaryLabel;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) WAUser *user;
@property (nonatomic) NSUInteger numberOfEvents;

+ (WASummaryPageView *)viewFromNib;

@end
