//
//  WANewDayEventViewCell.h
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *kWANewDayEventViewCellID;

@class WANewDayEvent;
@interface WANewDayEventViewCell : UICollectionViewCell <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *descriptionView;
@property (weak, nonatomic) IBOutlet UICollectionView *imageCollectionView;

@property (nonatomic, strong) WANewDayEvent *representingDayEvent;

@end
