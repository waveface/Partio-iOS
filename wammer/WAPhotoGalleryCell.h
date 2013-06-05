//
//  WAPhotoGalleryCell.h
//  wammer
//
//  Created by Shen Steven on 4/30/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"

@interface WAPhotoGalleryCell : UICollectionViewCell

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, weak) IBOutlet UIView *placeholderView;
@property (nonatomic, weak) IBOutlet NINetworkImageView *avatarView;
@property (nonatomic, weak) IBOutlet UILabel *creatorNameLabel;

- (void) setImage:(UIImage *)newImage animated:(BOOL)animated;
@end
