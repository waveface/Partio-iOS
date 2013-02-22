//
//  WANewDaySummaryViewCell.h
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *kWANewDaySummaryViewCellID;

@class WANewDaySummary;
@interface WANewDaySummaryViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *weekDayLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *yearLabel;
@property (weak, nonatomic) IBOutlet UIButton *photosButton;
@property (weak, nonatomic) IBOutlet UIButton *docsButton;
@property (weak, nonatomic) IBOutlet UIButton *websButton;
@property (weak, nonatomic) IBOutlet UILabel *greetingLabel;

- (IBAction)handlePhotosButtonPressed:(id)sender;
- (IBAction)handleDocsButtonPressed:(id)sender;
- (IBAction)handleWebsButtonPressed:(id)sender;

@property (nonatomic, strong) WANewDaySummary *representingDaySummary;

@end
