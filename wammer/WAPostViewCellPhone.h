//
//  WAArticleCommentsViewCell.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/12/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IRTableViewCell.h"
#import "WADataStore.h"

@class IRLabel, WAPreviewBadge, WAImageStackView, WAArticle;
@interface WAPostViewCellPhone : IRTableViewCell

@property (nonatomic, readonly, weak) WAArticle *article;	//	representedObject

@property (nonatomic, readwrite, strong) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *userNicknameLabel;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *contentDescriptionLabel;
@property (nonatomic, readwrite, strong) IBOutlet UITextView *contentTextView;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *dateOriginLabel;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *originLabel;
@property (nonatomic, readwrite, strong) IBOutlet IRLabel *commentLabel;
@property (nonatomic, readwrite, strong) IBOutlet WAPreviewBadge *previewBadge;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *extraInfoLabel;

@property (nonatomic, readwrite, strong) IBOutlet UIImageView *previewImageView;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *previewTitleLabel;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *previewProviderLabel;
@property (nonatomic, readwrite, strong) IBOutlet UIView *previewImageBackground;

@property (nonatomic, readwrite, strong) IBOutlet UILabel *dayLabel;
@property (nonatomic, readwrite, strong) IBOutlet UILabel *monthLabel;
@property (nonatomic, readwrite, strong) IBOutlet UIImageView *backgroundImageView;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *photoImageViews;

@end
