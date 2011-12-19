//
//  WAArticleView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 10/11/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WAArticle;
@class WAImageStackView, WAPreviewBadge, WAArticleTextEmphasisLabel;


@protocol WAArticleView

@property (nonatomic, readwrite, retain) WAArticle *article;

@property (nonatomic, readwrite, retain) UIView *contextInfoContainer;
@property (nonatomic, readwrite, retain) WAImageStackView *imageStackView;
@property (nonatomic, readwrite, retain) WAPreviewBadge *previewBadge;
@property (nonatomic, readwrite, retain) WAArticleTextEmphasisLabel *textEmphasisView;
@property (nonatomic, readwrite, retain) UIImageView *avatarView;
@property (nonatomic, readwrite, retain) UILabel *relativeCreationDateLabel;
@property (nonatomic, readwrite, retain) UILabel *userNameLabel;
@property (nonatomic, readwrite, retain) UILabel *articleDescriptionLabel;
@property (nonatomic, readwrite, retain) UILabel *deviceDescriptionLabel;
@property (nonatomic, readwrite, retain) UITextView *contextTextView;
@property (nonatomic, readwrite, retain) UIImageView *mainImageView;

@end


@interface WAArticleView : UIView <WAArticleView>

@property (nonatomic, readwrite, retain) WAArticle *article;

@property (nonatomic, readwrite, retain) IBOutlet UIView *contextInfoContainer;
@property (nonatomic, readwrite, retain) IBOutlet WAImageStackView *imageStackView;
@property (nonatomic, readwrite, retain) IBOutlet WAPreviewBadge *previewBadge;
@property (nonatomic, readwrite, retain) IBOutlet WAArticleTextEmphasisLabel *textEmphasisView;
@property (nonatomic, readwrite, retain) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *relativeCreationDateLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *userNameLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *articleDescriptionLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *deviceDescriptionLabel;
@property (nonatomic, readwrite, retain) IBOutlet UITextView *contextTextView;
@property (nonatomic, readwrite, retain) IBOutlet UIImageView *mainImageView;

@end
