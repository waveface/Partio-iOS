//
//  WAEventPeopleCell.h
//  wammer
//
//  Created by Shen Steven on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NINetworkImageView.h"

@interface WAEventPeopleCell : UITableViewCell

@property (nonatomic, strong) IBOutlet NINetworkImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;

@end
