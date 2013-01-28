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
@property (nonatomic, weak) IBOutlet UILabel *numberLabel;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UILabel *descriptiveTagsLabel;
@property (nonatomic, weak) IBOutlet UILabel *tagsLabel;

@property (nonatomic, weak) IBOutlet UIView *separatorLineAboveMap;
@property (nonatomic, weak) IBOutlet UIView *separatorLineBelowMap;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *descriptiveTagsLabelToTopConstrain;

@property (nonatomic, weak) IBOutlet UIView *avatarPlacehoder;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UIImageView *locationMarkImageView;

@property (nonatomic, weak) IBOutlet UILabel *labelOverSeparationLine;

@property (nonatomic, weak) IBOutlet UIButton *descriptionTapper;
@end
