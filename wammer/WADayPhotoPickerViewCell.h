//
//  WADayPhotoPickerViewCell.h
//  wammer
//
//  Created by Shen Steven on 4/8/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WADayPhotoPickerViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIImageView *checkMarkView;

@property (nonatomic, strong) NSOperation *imageLoadingOperation;
@property (nonatomic, strong) NSOperation *imageDisplayingOperation;
@end
