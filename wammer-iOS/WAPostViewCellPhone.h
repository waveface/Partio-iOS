//
//  WAArticleCommentsViewCell.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/12/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAImageStackView.h"

enum {
	WAPostViewCellStyleDefault,
	WAPostViewCellStyleImageStack
}; typedef NSUInteger WAPostViewCellStyle;


@interface WAPostViewCellPhone : UITableViewCell {
    UILabel *commentLabel;
}


- (id) initWithCommentsViewCellStyle:(WAPostViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, readwrite, retain) IBOutlet WAImageStackView *imageStackView;
@property (nonatomic, readwrite, retain) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *userNicknameLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *contentTextLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *dateOriginLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *originLabel;
@property (nonatomic, readwrite, retain) IBOutlet UIButton *extraInfoButton;
@property (nonatomic, retain) IBOutlet UILabel *commentLabel;

@end





@interface WAPostViewCellPhone (NibLoading)

+ (WAPostViewCellPhone *) cellFromNib;
+ (WAPostViewCellPhone *) cellFromNibNamed:(NSString *)nibName instantiatingOwner:(id)owner withOptions:(NSDictionary *)options;

@end
