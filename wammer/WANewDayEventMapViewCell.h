//
//  WANewDayEventMapViewCell.h
//  wammer
//
//  Created by kchiu on 13/2/20.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

extern NSString *kWANewDayEventMapViewCellID;

@interface WANewDayEventMapViewCell : UICollectionViewCell <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) UIImage *mapImage;

@end
