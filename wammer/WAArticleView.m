//
//  WAArticleView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 10/11/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleView.h"
#import "WAImageStackView.h"
#import "WAPreviewBadge.h"
#import "WAArticleTextEmphasisLabel.h"
#import "WADataStore.h"

#import "IRRelativeDateFormatter.h"
#import "WAArticleViewController.h"

#import "IRLifetimeHelper.h"


@interface WAArticleView ()

+ (IRRelativeDateFormatter *) relativeDateFormatter;

@end


@implementation WAArticleView

@synthesize contextInfoContainer, imageStackView, previewBadge, textEmphasisView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, deviceDescriptionLabel, contextTextView, mainImageView, contextWebView;

- (void) configureWithArticle:(WAArticle *)article {

	UIImage *representingImage = article.representingFile.thumbnailImage;
	
	userNameLabel.text = article.owner.nickname;
	relativeCreationDateLabel.text = [[[self class] relativeDateFormatter] stringFromDate:article.creationDate];
	articleDescriptionLabel.text = article.text;
	previewBadge.preview = [article.previews anyObject];
	imageStackView.images = representingImage ? [NSArray arrayWithObject:representingImage] : nil;
	mainImageView.image = representingImage;
	mainImageView.backgroundColor = representingImage ? [UIColor clearColor] : [UIColor colorWithWhite:0.5 alpha:1];
	avatarView.image = article.owner.avatar;
	deviceDescriptionLabel.text = article.creationDeviceName;
	textEmphasisView.text = article.text;
	textEmphasisView.hidden = !!(BOOL)[article.files count];
	contextInfoContainer.hidden = ![article.text length];
	
}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	if (userNameLabel && relativeCreationDateLabel && deviceDescriptionLabel) {
		
		[userNameLabel sizeToFit];
		[relativeCreationDateLabel sizeToFit];
		[relativeCreationDateLabel irPlaceBehindLabel:userNameLabel withEdgeInsets:(UIEdgeInsets){ 0, -8, 0, -8 }];
		[deviceDescriptionLabel sizeToFit];
		[deviceDescriptionLabel irPlaceBehindLabel:relativeCreationDateLabel withEdgeInsets:(UIEdgeInsets){ 0, -8, 0, -8 }];
		
	}
	
	CGRect oldDescriptionFrame = self.articleDescriptionLabel.frame;
	
	CGSize fitSize = [self.articleDescriptionLabel sizeThatFits:(CGSize){
		self.contextInfoContainer.frame.size.width - 16,
		64
	}];
	
	fitSize.height = MAX(24, MIN(fitSize.height, 64));
	CGFloat heightDelta = fitSize.height - CGRectGetHeight(self.articleDescriptionLabel.frame);
	self.articleDescriptionLabel.frame = IRGravitize(oldDescriptionFrame, fitSize, kCAGravityBottomLeft);
	
	CGSize newContextInfoContainerSize = self.contextInfoContainer.frame.size;
	newContextInfoContainerSize.height += heightDelta;
	
	self.contextInfoContainer.frame = IRGravitize(self.contextInfoContainer.frame, newContextInfoContainerSize, kCAGravityBottomLeft);

}

+ (IRRelativeDateFormatter *) relativeDateFormatter {

	static IRRelativeDateFormatter *formatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{

		formatter = [[IRRelativeDateFormatter alloc] init];
		formatter.approximationMaxTokenCount = 1;
			
	});

	return formatter;

}

@end
