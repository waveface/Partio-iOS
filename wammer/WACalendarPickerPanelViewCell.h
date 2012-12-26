//
//  WACalendarPickerPanelViewCell.h
//  wammer
//
//  Created by Greener Chen on 12/12/26.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WACalendarPickerPanelViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton *eventsButton;
@property (nonatomic, weak) IBOutlet UIButton *photosButton;
@property (nonatomic, weak) IBOutlet UIButton *docsButton;
@property (nonatomic, weak) IBOutlet UIButton *webpagesButton;

@end
