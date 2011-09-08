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
	WAPostViewCellStyleImageStack,
    WAPostViewCellStyleCompact,
    WAPostViewCellStyleCompactWithImageStack
}; typedef NSUInteger WAPostViewCellStyle;


@interface WAPostViewCellPhone : UITableViewCell {
    UILabel *commentLabel;
    UIImageView *commentBackground;
    WAImageStackView *imageStackView;
}


- (id) initWithPostViewCellStyle:(WAPostViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void) setCommentCount:(NSUInteger)commentCount;

@property (nonatomic, retain) IBOutlet WAImageStackView *imageStackView;
@property (nonatomic, readwrite, retain) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *userNicknameLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *contentTextLabel;
@property (retain, nonatomic) IBOutlet UITextView *contentTextView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *dateOriginLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *originLabel;
@property (nonatomic, retain) IBOutlet UILabel *commentLabel;
@property (nonatomic, retain) IBOutlet UIImageView *commentBackground;

@end

@interface WAPostViewCellPhone (NibLoading)

+ (WAPostViewCellPhone *) cellFromNib;
+ (WAPostViewCellPhone *) cellFromNibNamed:(NSString *)nibName instantiatingOwner:(id)owner withOptions:(NSDictionary *)options;

@end
