//
//  WASummaryViewController.h
//  wammer
//
//  Created by kchiu on 13/1/21.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WASummaryViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *photosButton;
@property (weak, nonatomic) IBOutlet UIButton *documentsButton;
@property (weak, nonatomic) IBOutlet UIButton *webpagesButton;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *weekDayLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *helloLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventSummaryLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *eventScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *eventPageControll;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

- (id)initWithDate:(NSDate *)date;

@end
