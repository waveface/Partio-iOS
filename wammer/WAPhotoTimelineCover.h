//
//  WAPhotoTimelineCover.h
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Nimbus/NINetworkImageView.h>
#import <MapKit/MapKit.h>

@interface WAPhotoTimelineCover : UICollectionReusableView

@property (nonatomic, weak) IBOutlet UIImageView *coverImageView;
@property (nonatomic, weak) IBOutlet UIView *gradientBackground;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *detailButton;
@property (nonatomic, weak) IBOutlet UIView *informationView;
@property (nonatomic, weak) IBOutlet NINetworkImageView *avatarView;
@property (nonatomic, weak) IBOutlet UILabel *informationLabel;
@end
