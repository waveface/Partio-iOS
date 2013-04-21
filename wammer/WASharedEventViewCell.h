//
//  WASharedEventViewCell.h
//  wammer
//
//  Created by Greener Chen on 13/4/11.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WASharedEventViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIImageView *stickerNew;
@property (nonatomic, strong) IBOutlet UIImageView *photoIcon;
@property (nonatomic, strong) IBOutlet UILabel *photoNumber;
@property (nonatomic, strong) IBOutlet UIImageView *checkinIcon;
@property (nonatomic, strong) IBOutlet UILabel *checkinNumber;
@property (nonatomic, strong) IBOutlet UILabel *date;
@property (nonatomic, strong) IBOutlet UILabel *location;
@property (nonatomic, strong) IBOutlet UIImageView *peopleIcon;
@property (nonatomic, strong) IBOutlet UILabel *peopleNumber;
@property (nonatomic, strong) IBOutlet UIView *infoView;
@end
