//
//  WAPhotoGroupViewCell.h
//  wammer
//
//  Created by Shen Steven on 4/4/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAGeoLocation.h"
#import <FacebookSDK/FacebookSDK.h>

@interface WAPhotoHighlightViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *bgImageView;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *photoNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UIButton *addButton;
@property (nonatomic, strong) WAGeoLocation *geoLocation;
@property (nonatomic, strong) FBRequestConnection *fbRequest;

@end
