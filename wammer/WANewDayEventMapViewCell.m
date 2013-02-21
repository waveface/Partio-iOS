//
//  WANewDayEventMapViewCell.m
//  wammer
//
//  Created by kchiu on 13/2/20.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDayEventMapViewCell.h"
#import <Foundation+IRAdditions.h>

NSString *kWANewDayEventMapViewCellID = @"NewDayEventMapViewCellID";

@implementation WANewDayEventMapViewCell

- (void)awakeFromNib {
  UIGraphicsBeginImageContext(self.mapView.frame.size);
  [self.mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
  self.mapImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
}

- (void)prepareForReuse {
  [self.mapView removeAnnotations:self.mapView.annotations];
}

- (void)dealloc {
  self.mapView.delegate = nil;
}

@end
