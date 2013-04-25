//
//  WAEventDetailsCell.h
//  wammer
//
//  Created by Shen Steven on 4/24/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Nimbus/NINetworkImageView.h>

@interface WAEventDetailsCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *emailLabel;
@property (nonatomic, weak) IBOutlet NINetworkImageView *avatarView;
@end
