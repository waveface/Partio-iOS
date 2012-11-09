//
//  WAEventHeaderView.h
//  wammer
//
//  Created by Shen Steven on 11/6/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface WAEventHeaderView : UICollectionReusableView

+ (id)viewFromNib;

@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UILabel *descriptiveTagsLabel;
@property (nonatomic, weak) IBOutlet UILabel *tagsLabel;

@end
