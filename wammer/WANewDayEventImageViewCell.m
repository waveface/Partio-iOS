//
//  WANewDayEventImageViewCell.m
//  wammer
//
//  Created by kchiu on 13/2/14.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDayEventImageViewCell.h"

NSString *kWANewDayEventImageViewCellID = @"NewDayEventImageViewCellID";

@implementation WANewDayEventImageViewCell

- (void)prepareForReuse {
  self.imageView.image = nil;
}

@end
