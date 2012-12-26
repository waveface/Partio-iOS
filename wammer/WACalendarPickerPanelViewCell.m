//
//  WACalendarPickerPanelViewCell.m
//  wammer
//
//  Created by Greener Chen on 12/12/26.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerPanelViewCell.h"

NSString * const kWACalendarPickerPanelViewCell = @"WACalendarPickerPanelViewCell";

@implementation WACalendarPickerPanelViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	//self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  self = [[NSBundle mainBundle] loadNibNamed:kWACalendarPickerPanelViewCell owner:self options:nil][0];
	
	if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
