//
//  WAArticleCommentsViewCell.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/12/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAImageStackView.h"
#import "WAPreviewBadge.h"
#import "IRGradientView.h"
#import "IRLabel.h"
#import "WAArticle.h"
#import "WATapestryView.h"
enum {
	WAPostViewCellStyleDefault,
	WAPostViewCellStyleImageStack,
  WAPostViewCellStyleWebLink, // tag 0
  WAPostViewCellStyleWebLinkWithoutPhoto, // tag 1
}; typedef NSUInteger WAPostViewCellStyle;


@interface WAPostViewCellPhone : UITableViewCell

- (id) initWithPostViewCellStyle:(WAPostViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, retain, readwrite) WAArticle *post;
@property (nonatomic, retain) IBOutlet WAImageStackView *imageStackView;
@property (nonatomic, readwrite, retain) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *userNicknameLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *contentDescriptionLabel;
@property (retain, nonatomic) IBOutlet UITextView *contentTextView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *dateOriginLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *dateLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *originLabel;
@property (nonatomic, retain) IBOutlet IRLabel *commentLabel;
@property (nonatomic, readwrite, retain) IBOutlet WAPreviewBadge *previewBadge;
@property (retain, nonatomic) IBOutlet UILabel *extraInfoLabel;

// preview cell
@property (retain, nonatomic) IBOutlet UIImageView *previewImageView;
@property (retain, nonatomic) IBOutlet UILabel *previewTitleLabel;
@property (retain, nonatomic) IBOutlet UILabel *previewProviderLabel;
@property (retain, nonatomic) IBOutlet UIView *previewImageBackground;

@property (strong, nonatomic) IBOutlet UILabel *dayLabel;
@property (strong, nonatomic) IBOutlet UILabel *monthLabel;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end

@interface WAPostViewCellPhone (NibLoading)

+ (WAPostViewCellPhone *) cellFromNib;
+ (WAPostViewCellPhone *) cellFromNibNamed:(NSString *)nibName instantiatingOwner:(id)owner withOptions:(NSDictionary *)options;

@end
