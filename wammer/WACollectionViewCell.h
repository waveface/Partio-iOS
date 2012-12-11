//
//  WACollectionViewCell.h
//  wammer
//
//  Created by jamie on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WACollectionViewCell : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *count;

@end

extern NSString * const kCollectionViewCellID;