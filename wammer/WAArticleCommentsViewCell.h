//
//  WAArticleCommentsViewCell.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/12/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
	WAArticleCommentsViewCellStyleDefault = 0,
	WAArticleCommentsViewCellStyleImageStack = 1
}; typedef NSUInteger WAArticleCommentsViewCellStyle;


@interface WAArticleCommentsViewCell : UITableViewCell

- (id) initWithCommentsViewCellStyle:(WAArticleCommentsViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, readwrite, retain) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *userNicknameLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *contentTextLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *dateOriginLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *originLabel;

@end





@interface WAArticleCommentsViewCell (NibLoading)

+ (WAArticleCommentsViewCell *) cellFromNib;
+ (WAArticleCommentsViewCell *) cellFromNibNamed:(NSString *)nibName instantiatingOwner:(id)owner withOptions:(NSDictionary *)options;

@end
