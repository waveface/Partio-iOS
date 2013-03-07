//
//  WACollectionViewCell.h
//  wammer
//
//  Created by jamie on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAFile.h"

@interface WACollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) WAFile *cover;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *count;

- (void) setImage: (UIImage*)image;

@end

extern NSString * const kCollectionViewCellID;