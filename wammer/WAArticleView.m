//
//  WAArticleView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 10/11/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleView.h"

#import "WAPreviewBadge.h"
#import "WAArticleTextEmphasisLabel.h"
#import "WADataStore.h"

#import "Foundation+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"

#import "WFPresentation.h"

#import <AssetsLibrary/AssetsLibrary.h>

@interface WAArticleView ()

+ (IRRelativeDateFormatter *) relativeDateFormatter;
+ (NSDateFormatter *) absoluteDateFormatter;

- (WFPresentationTemplate *) presentationTemplate;

@property (nonatomic, readwrite, weak) WAArticle *article;

@end


@implementation WAArticleView

@synthesize contextInfoContainer, previewBadge, textEmphasisView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, deviceDescriptionLabel, contextTextView, mainImageView, contextWebView, presentationTemplateName;
@synthesize article;

- (void) awakeFromNib {

	[super awakeFromNib];
	
	self.articleDescriptionLabel.font = [UIFont fontWithName:@"FontinSans-Italic" size:20.0f];

}

- (WFPresentationTemplate *) presentationTemplate {

	NSParameterAssert(self.presentationTemplateName);
	
	return [WFPresentationTemplate templateNamed:self.presentationTemplateName];

}

- (void) configureWithArticle:(WAArticle *)inArticle {

	self.article = inArticle;
	
	BOOL isFavorite = [inArticle.favorite isEqualToNumber:(NSNumber *)kCFBooleanTrue];

	NSString *dateString = nil;
	if ([article.creationDate compare:[NSDate dateWithTimeIntervalSinceNow:-24*60*60]] == NSOrderedDescending) {
		
		dateString = [[[self class] relativeDateFormatter] stringFromDate:article.creationDate];
		
	} else {
	
		dateString = [[[self class] absoluteDateFormatter] stringFromDate:article.creationDate];
	
	}
	
	WAPreview *shownPreview = [article.previews anyObject];
	userNameLabel.text = article.owner.nickname;
	
	NSString *photoInformation = NSLocalizedString(@"PHOTO_NOUN", @"In iPad overview");
		
	if ([article.files count] > 1) {
	
		photoInformation  = [NSString localizedStringWithFormat:
			NSLocalizedString(@"PHOTOS_PLURAL", @"In iPad overview"),
			[inArticle.files count]
		];
			
	}
	
	NSString *postDescription = [NSString localizedStringWithFormat:NSLocalizedString(@"NUMBER_OF_PHOTOS_CREATE_TIME_FROM_DEVICE", @"In iPad overview"), photoInformation, dateString, article.creationDeviceName];
	relativeCreationDateLabel.text = postDescription;
	articleDescriptionLabel.text = inArticle.text;
	previewBadge.preview = shownPreview;

	[mainImageView irUnbind:@"image"];
	if (isFavorite)
		[mainImageView irBind:@"image"
					 toObject:inArticle
					  keyPath:@"representingFile.bestPresentableImage"
					  options:[NSDictionary dictionaryWithObjectsAndKeys: (id)kCFBooleanTrue,
							   kIRBindingsAssignOnMainThreadOption, nil]];
	else
		[mainImageView irBind:@"image"
					 toObject:inArticle
					  keyPath:@"representingFile.smallThumbnailImage"
					  options:[NSDictionary dictionaryWithObjectsAndKeys: (id)kCFBooleanTrue,
							   kIRBindingsAssignOnMainThreadOption, nil]];
	
	avatarView.image = inArticle.owner.avatar;
	deviceDescriptionLabel.text = inArticle.creationDeviceName;
	textEmphasisView.text = inArticle.text;
	textEmphasisView.hidden = !!(BOOL)[inArticle.files count];
	//contextInfoContainer.hidden = ![article.text length]; // if there's no note, display nothing.
	
	if (contextWebView) {
	
		[contextWebView loadHTMLString:nil baseURL:nil];
	
		__weak UIWebView *wContextWebView = contextWebView;
		__weak WAArticleView *wSelf = self;
		__weak WAArticle *wArticle = inArticle;
		__weak WAPreview *wPreview = shownPreview;
		
		CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
		
			if (!wSelf || !wArticle || !wContextWebView)
				return;
			
			NSString *footerText = [NSString localizedStringWithFormat:NSLocalizedString(@"CREATE_TIME_FROM_DEVICE", @"In iPad overview, (time, device)"), dateString, wArticle.creationDeviceName];
			
			WFPresentationTemplate *pt = [wSelf presentationTemplate];
			NSMutableDictionary *replacements = [NSMutableDictionary dictionary];
			
			void (^hook)(NSString *, NSString *) = ^ (NSString *key, NSString *value) {
				
				[replacements setObject:(value ? value : @"")	forKey:key];
				
			};
			
			hook(@"$ADDITIONAL_HTML_CLASSES", [[NSArray arrayWithObjects:
				(wPreview ? @"preview" : @"no-preview"),
				([wArticle.text length] ? @"body" : @"no-body"),
			nil] componentsJoinedByString:@" "]);
			
			hook(@"$TITLE", [wArticle.text substringToIndex: MIN( 120, [wArticle.text length])] );
			hook(@"$ADDITIONAL_STYLES", nil);
			hook(@"$BODY", wArticle.text);
			hook(@"$PREVIEW_TITLE", wPreview.graphElement.title);
			hook(@"$PREVIEW_PROVIDER", [wPreview.graphElement providerCaption]);
			hook(@"$PREVIEW_IMAGE", wPreview.graphElement.representingImage.imageRemoteURL);
			hook(@"$PREVIEW_BODY", wPreview.graphElement.text);
			hook(@"$FOOTER", footerText);
			
			NSString *string = [pt documentWithReplacementVariables:replacements];
			
			if (wContextWebView.window)
				[wContextWebView loadHTMLString:string baseURL:pt.baseURL];
			
		});
	
	}
	
}

- (void) willMoveToWindow:(UIWindow *)newWindow {

	[super willMoveToWindow:newWindow];
	
	if (newWindow && self.article)
		[self configureWithArticle:self.article];
	
	if (!newWindow)
		[contextWebView stopLoading];

}

- (void) willMoveToSuperview:(UIView *)newSuperview {

	if (!newSuperview)
		[contextWebView stopLoading];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
//	if (userNameLabel && relativeCreationDateLabel && deviceDescriptionLabel) {
//		
//		[userNameLabel sizeToFit];
//		[deviceDescriptionLabel sizeToFit];
//		[deviceDescriptionLabel irPlaceBehindLabel:relativeCreationDateLabel withEdgeInsets:(UIEdgeInsets){ 0, -8, 0, -8 }];
//		
//	}

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

+ (NSDateFormatter *) absoluteDateFormatter {

	static NSDateFormatter *formatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	
		formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterLongStyle;
			
	});

	return formatter;

}

@end
