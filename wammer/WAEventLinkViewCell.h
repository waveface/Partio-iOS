//
//  WAEventLinkViewCell.h
//  wammer
//
//  Created by Shen Steven on 11/6/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAEventLinkViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *webTitle;
@property (nonatomic, weak) IBOutlet UILabel *webURL;

@end
