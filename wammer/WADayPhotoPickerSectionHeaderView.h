//
//  WADayPhotoPickerSectionHeaderView.h
//  wammer
//
//  Created by Shen Steven on 4/8/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAGeoLocation.h"

@interface WADayPhotoPickerSectionHeaderView : UICollectionReusableView

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, strong) WAGeoLocation *geoLocation;

@end
