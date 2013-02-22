//
//  WANewDayEventMapViewCell.m
//  wammer
//
//  Created by kchiu on 13/2/20.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDayEventMapViewCell.h"
#import <Foundation+IRAdditions.h>
#import <Nimbus/NINetworkImageView.h>

NSString *kWANewDayEventMapViewCellID = @"NewDayEventMapViewCellID";

@implementation WANewDayEventMapViewCell

- (void)prepareForReuse {

  [self.mapImageView prepareForReuse];

}

@end
