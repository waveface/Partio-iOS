//
//  WAUserInfoHeaderCell.h
//  wammer
//
//  Created by Evadne Wu on 12/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAUserInfoHeaderCell : UITableViewCell

+ (WAUserInfoHeaderCell *) cellFromNib;

@property (retain, nonatomic) IBOutlet UIImageView *avatarView;
@property (retain, nonatomic) IBOutlet UILabel *userNameLabel;
@property (retain, nonatomic) IBOutlet UILabel *userEmailLabel;

@end
