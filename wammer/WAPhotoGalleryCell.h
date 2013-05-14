//
//  WAPhotoGalleryCell.h
//  wammer
//
//  Created by Shen Steven on 4/30/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAPhotoGalleryCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIView *subtitleView;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@end
