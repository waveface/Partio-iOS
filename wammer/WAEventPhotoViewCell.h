//
//  WAEventPhotoViewCell.h
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAEventPhotoViewCell : UICollectionViewCell

@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *checkMarkView;

@end
