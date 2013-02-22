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

@class NINetworkImageView;
@interface WANewDayEventMapViewCell : UICollectionViewCell <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet NINetworkImageView *mapImageView;

@end
