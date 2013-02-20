//
//  WANewDayEventMapViewCell.m
//  wammer
//
//  Created by kchiu on 13/2/20.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDayEventMapViewCell.h"

NSString *kWANewDayEventMapViewCellID = @"NewDayEventMapViewCellID";

@implementation WANewDayEventMapViewCell

- (void)prepareForReuse {
  [self.mapView removeAnnotations:self.mapView.annotations];
  self.mapImage = nil;
}

- (void)dealloc {
  self.mapView.delegate = nil;
}

#pragma mark - MKMapView delegates

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
  
  __weak WANewDayEventMapViewCell *wSelf = self;
  
  double delayInSeconds = 3.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    UIGraphicsBeginImageContext(mapView.frame.size);
    [mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
    wSelf.mapImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  });
  
}

@end
