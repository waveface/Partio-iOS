//
//  WAPreviewBadge.m
//  wammer-iOS
//
//  Created by Evadne Wu on 9/13/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WADataStore.h"
#import "WAPreviewBadge.h"
#import "WAImageView.h"

#import "CoreText+IRAdditions.h"
#import "CGGeometry+IRAdditions.h"
#import "UIKit+IRAdditions.h"


@interface WAPreviewBadge ()

- (void) waSharedInit;

@property (nonatomic, readonly, assign) WAPreviewBadgeStyle suggestedStyle;

@property (nonatomic, readwrite, retain) UIImageView *imageView;
@property (nonatomic, readwrite, retain) IRLabel *label;

@property (nonatomic, readonly, retain) NSAttributedString *attributedText; 

- (void) layoutImageAndTextStyle;
- (void) layoutImageOnlyStyle;
- (void) layoutTextOnlyStyle;
- (void) layoutTextOverImageStyle;

@end


@implementation WAPreviewBadge

@synthesize preview, style;
@synthesize titleFont, titleColor, titlePlaceholder, titlePlaceholderColor;
@synthesize providerNameFont, providerNameColor, providerNamePlaceholder, providerNamePlaceholderColor;
@synthesize textFont, textColor, textPlaceholder, textPlaceholderColor;

@synthesize imageView, label, backgroundView;
@synthesize minimumAcceptibleFullFrameAspectRatio;
@synthesize gutterWidth;


- (id) initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	[self waSharedInit];
	
	return self;
	
}

- (void) awakeFromNib {

	[super awakeFromNib];
	[self waSharedInit];

}

+ (NSSet *) keyPathsForValuesAffectingAttributedText {

	return [NSSet setWithObjects:
	
		@"title",
		@"providerName",
		@"text",
	
		@"titleFont",
		@"titleColor",
		@"titlePlaceholder",
		@"titlePlaceholderColor",
		
		@"providerNameFont",
		@"providerNameColor",
		@"providerNamePlaceholder",
		@"providerNamePlaceholderColor",
		
		@"textFont",
		@"textColor",
		@"textPlaceholder",
		@"textPlaceholderColor",
	
	nil];

}

- (NSAttributedString *) attributedText {

	NSMutableAttributedString *returnedString = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
	
	NSAttributedString * (^append)(NSString *, NSString *, UIFont *, UIColor *, UIColor *, NSDictionary *) = ^ (NSString *string, NSString *placeholder, UIFont *font, UIColor *color, UIColor *placeholderColor, NSDictionary *otherAttrs) {
	
		NSString * const usedString = string ? string : placeholder;
		if (!usedString)	//	ZERO length strings still occupy space
			return (NSAttributedString *)nil;
		
		UIColor * const usedColor = string ? color : (placeholderColor ? placeholderColor : color);
		
		NSDictionary * const baseAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		
			//  Global attributes here
			
			(id)[font irFixedLineHeightParagraphStyle], kCTParagraphStyleAttributeName,
		
		nil];
		
		NSDictionary * const usedAttrs = [[[NSAttributedString irAttributesForFont:font color:usedColor] irDictionaryByMergingWithDictionary:baseAttrs] irDictionaryByMergingWithDictionary:otherAttrs];
		
		NSAttributedString *appendedString = [[[NSAttributedString alloc] initWithString:usedString attributes:usedAttrs] autorelease];
		[returnedString appendAttributedString:appendedString];

		return appendedString;
		
	};
	
	id titleElement = append(self.title, self.titlePlaceholder, self.titleFont, self.titleColor, self.titlePlaceholderColor, [NSDictionary dictionaryWithObjectsAndKeys:
		
			self.link, kIRTextLinkAttribute,
			(id)[UIFont irFixedLineHeightParagraphStyleForHeight:(self.titleFont.leading - 4)], kCTParagraphStyleAttributeName,
		
	nil]);
	
	if (titleElement)
		append(@"\n", nil, [UIFont systemFontOfSize:self.gutterWidth], [UIColor clearColor], nil, [NSDictionary dictionaryWithObjectsAndKeys:
			(id)[UIFont irFixedLineHeightParagraphStyleForHeight:1.0], kCTParagraphStyleAttributeName,
		nil]);
			
	id providerElement = append(self.providerName, self.providerNamePlaceholder, self.providerNameFont, self.providerNameColor, self.providerNamePlaceholderColor, nil);
	
	if (titleElement || providerElement) {
		append(@"\n \n", nil, [UIFont systemFontOfSize:self.gutterWidth], [UIColor clearColor], nil, [NSDictionary dictionaryWithObjectsAndKeys:
			(id)[UIFont irFixedLineHeightParagraphStyleForHeight:12.0], kCTParagraphStyleAttributeName,
		nil]);
	}
	
	append(self.text, self.textPlaceholder, self.textFont, self.textColor, self.textPlaceholderColor, nil);
	
	return returnedString;

}

- (void) waSharedInit {

	self.minimumAcceptibleFullFrameAspectRatio = 0.85f;
	self.gutterWidth = 12.0f;
	
	self.titlePlaceholder	= NSLocalizedString(@"PREVIEW_BADGE_TITLE_PLACEHOLDER", @"Text to show for previews without a title");
	self.titleFont = [UIFont boldSystemFontOfSize:24.0f];
	self.titleColor = [UIColor colorWithRed:0 green:0 blue:0.45f alpha:1.0f];
	self.titlePlaceholderColor = [UIColor grayColor];
	
	self.providerNamePlaceholder = NSLocalizedString(@"PREVIEW_BADGE_PROVIDER_NAME_PLACEHOLDER", @"Text to show for previews without a provider name");
	self.providerNameFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0];
	self.providerNameColor = [UIColor colorWithWhite:0.65 alpha:1];
	self.providerNamePlaceholderColor = [UIColor grayColor];
	
	self.textPlaceholder = NSLocalizedString(@"PREVIEW_BADGE_TEXT_PLACEHOLDER", @"Text to show for previews without body text");
	self.textFont = [UIFont systemFontOfSize:16.0f];
	self.textColor = [UIColor colorWithWhite:0.3 alpha:1];
	self.textPlaceholderColor = [UIColor grayColor];
	
	self.backgroundColor = nil;
	self.opaque = NO;
	
	self.backgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
	self.backgroundView.opaque = NO;
	self.backgroundView.backgroundColor = nil;
	self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	UIView *innerBackgroundView = [[[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.backgroundView.bounds, (UIEdgeInsets){ -4, -4, -4, -4 })] autorelease];
	innerBackgroundView.layer.contents = (id)[UIImage imageNamed:@"WAPreviewBadge"].CGImage;
	innerBackgroundView.layer.contentsCenter = (CGRect){ 10.0/24.0, 10.0/24.0, 4.0/24.0, 4.0/24.0 };
	innerBackgroundView.opaque = NO;
	innerBackgroundView.backgroundColor = nil;
	innerBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.backgroundView addSubview:innerBackgroundView];
	
	
	__block __typeof__(self) nrSelf = self;
	
	[self irAddObserverBlock: ^ (id inOldValue, id inNewValue, NSKeyValueChange changeKind) {
		
		[nrSelf setNeedsLayout];
		
	} forKeyPath:@"suggestedStyle" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
	
	[self setNeedsLayout];

}

+ (NSSet *) keyPathsForValuesAffectingSuggestedStyle {

	return [NSSet setWithObjects:
	
		@"title",
		@"text",
		@"image",
	
	nil];

}

- (WAPreviewBadgeStyle) suggestedStyle {

	if (!self.title && !self.text && self.image)
		return WAPreviewBadgeImageOnlyStyle;
	
	if ((self.title || self.text) && !self.image)
		return WAPreviewBadgeTextOnlyStyle;
			
	return WAPreviewBadgeImageAndTextStyle;

}

- (void) setStyle:(WAPreviewBadgeStyle)newStyle {

	if (style == newStyle)
		return;
	
	style = newStyle;
	
	[self setNeedsLayout];

}

- (UIImageView *) imageView {

	if (imageView)
		return imageView;
	
	imageView = [[WAImageView alloc] initWithImage:nil];
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.clipsToBounds = YES;
	
	[imageView irBind:@"image" toObject:self keyPath:@"image" options:nil];
	
	return imageView;

}

- (IRLabel *) label {

	if (label)
		return label;

	label = [[IRLabel alloc] init];
	label.backgroundColor = nil;
	label.opaque = NO;
	label.userInteractionEnabled = YES;
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	[label irBind:@"attributedText" toObject:self keyPath:@"attributedText" options:nil];
	
	return label;

}

- (void) setBackgroundView:(UIView *)newBackgroundView {

	if (backgroundView == newBackgroundView)
		return;
	
	[backgroundView removeFromSuperview];
	[backgroundView release];
	
	backgroundView = [newBackgroundView retain];
	[self addSubview:backgroundView];

}

- (void) layoutSubviews {

	[super layoutSubviews];
		
	self.backgroundView.frame = self.bounds;
	
	WAPreviewBadgeStyle const usedStyle = (self.style != WAPreviewBadgeAutomaticStyle) ? self.style : [self suggestedStyle];
	
	if ((BOOL[]){
		
		[WAPreviewBadgeImageAndTextStyle] = YES,
		[WAPreviewBadgeImageOnlyStyle] = YES,
		[WAPreviewBadgeTextOnlyStyle] = NO,
		[WAPreviewBadgeTextOverImageStyle] = YES
		
	}[usedStyle] && (self.imageView.superview != self)) {
	
		[self addSubview:self.imageView];
	
	};
	
	if ((BOOL[]){
		
		[WAPreviewBadgeImageAndTextStyle] = YES,
		[WAPreviewBadgeImageOnlyStyle] = NO,
		[WAPreviewBadgeTextOnlyStyle] = YES,
		[WAPreviewBadgeTextOverImageStyle] = YES
		
	}[usedStyle] && (self.label.superview != self)) {
	
		[self addSubview:self.label];
	
	};

	switch (usedStyle) {
		
		case WAPreviewBadgeImageAndTextStyle: {
			[self layoutImageAndTextStyle];
			break;
		}		
		
		case WAPreviewBadgeImageOnlyStyle: {
			[self layoutImageOnlyStyle];
			break;
		}
	
		case WAPreviewBadgeTextOnlyStyle: {
			[self layoutTextOnlyStyle];
			break;
		}
		
		case WAPreviewBadgeTextOverImageStyle: {
			[self layoutTextOverImageStyle];
			break;
		}
		
	}

}

- (void) layoutImageAndTextStyle {

	CGRect usableRect = CGRectStandardize(UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8 }));
	CGRect imageRect = IRCGSizeGetCenteredInRect((CGSize){
		CGRectGetHeight(self.bounds),
		CGRectGetHeight(self.bounds)
	}, usableRect, 0, YES);
	imageRect.origin.x = 8;
	imageRect.origin.y = 8;
	
	CGRect actualImageRect = IRCGRectAlignToRect(
		IRCGSizeGetCenteredInRect((CGSize) {
			self.image.size.width * 128,
			self.image.size.height * 128
		}, imageRect, 0.0f, YES),
		imageRect,
		//	UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8}), 
		irTopLeft, 
		YES
	);
	
	BOOL verticalLayout = (actualImageRect.size.width == usableRect.size.width);
	
	if (verticalLayout) {
		actualImageRect.size.height = MIN(actualImageRect.size.height, 0.55f * usableRect.size.height);
	} else {
		actualImageRect.size.width = MIN(actualImageRect.size.width, 0.55f * usableRect.size.width);
	}
	
	self.imageView.frame = actualImageRect;
	
	CGRect labelRect, tempRect;
	CGRectDivide(self.bounds, &tempRect, &labelRect,
		verticalLayout ? actualImageRect.size.height : actualImageRect.size.width,
		verticalLayout ? CGRectMinYEdge : CGRectMinXEdge
	);
	labelRect.origin.x += verticalLayout ? 8 : 16;
	labelRect.origin.y += verticalLayout ? 16 : 8;
	labelRect.size.height -= verticalLayout ? 24 : 16;
	labelRect.size.width -= verticalLayout ? 16 : 24;
	
	self.label.frame = CGRectIntegral(labelRect);
	
	CGFloat coverageRatio = (actualImageRect.size.width * actualImageRect.size.height) / (imageRect.size.width * imageRect.size.height);
	if (coverageRatio > self.minimumAcceptibleFullFrameAspectRatio) {
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	} else {
		self.imageView.contentMode = UIViewContentModeScaleAspectFill;
		self.imageView.frame = (CGRect){
			self.imageView.frame.origin,
			(CGSize){
				verticalLayout ? usableRect.size.width : self.imageView.frame.size.width,
				verticalLayout ? self.imageView.frame.size.height : usableRect.size.height
			}
		};
	}

}

- (void) layoutImageOnlyStyle {

	self.imageView.frame = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8 });

}

- (void) layoutTextOnlyStyle {

	self.label.frame = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8 });

}

- (void) layoutTextOverImageStyle {

	self.imageView.frame = self.bounds;
	
	if (![self.imageView.subviews count]) {
	
		UIView *overlay = [[[UIView alloc] initWithFrame:self.imageView.bounds] autorelease];
		overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		overlay.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85];
		
		[self.imageView addSubview:overlay];
	
	}
	
	CGRect usableLabelFrame = CGRectInset(self.bounds, 16, 12);
	
	self.label.frame = usableLabelFrame;
	self.label.backgroundColor = nil;
	
	self.imageView.contentMode = UIViewContentModeScaleAspectFill;
	
	self.titleFont = [UIFont boldSystemFontOfSize:24.0f];
	self.titleColor = [UIColor colorWithWhite:0.125 alpha:1];

	self.providerNameFont = [UIFont systemFontOfSize:14.0f];
	self.providerNameColor = [UIColor colorWithWhite:0 alpha:1];
	
	self.textFont = [UIFont systemFontOfSize:18.0f];
	self.textColor = [UIColor colorWithWhite:0.125 alpha:1];
	
	[self bringSubviewToFront:self.label];

}

+ (NSSet *) keyPathsForValuesAffectingTitle {

	return [NSSet setWithObject:@"preview.graphElement.title"];

}

- (NSString *) title {

	return self.preview.graphElement.title;
	
}

+ (NSSet *) keyPathsForValuesAffectingProviderName {

	return [NSSet setWithObject:@"preview.graphElement.providerCaption"];

}

- (NSString *) providerName {

	return self.preview.graphElement.providerCaption;
	
}

+ (NSSet *) keyPathsForValuesAffectingText {

	return [NSSet setWithObject:@"preview.graphElement.text"];

}


- (NSString *) text {

	return [self.preview.graphElement.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

}

+ (NSSet *) keyPathsForValuesAffectingImage {

	return [NSSet setWithObject:@"preview.thumbnail"];

}

- (UIImage *) image {

	return self.preview.thumbnail;

}

+ (NSSet *) keyPathsForValuesAffectingLink {

	return [NSSet setWithObject:@"preview.graphElement.url"];

}

- (NSURL *) link {

	if (self.preview.graphElement.url)
		return [NSURL URLWithString:self.preview.graphElement.url];
	
	return nil;

}

- (void) setPreview:(WAPreview *)newPreview {

	if (preview == newPreview)
		return;

	[preview release];
	preview = [newPreview retain];
		
	[self setNeedsLayout];

}

- (NSString *) accessibilityLabel {

	return @"Preview Badge";

}

+ (NSSet *) keyPathsForValuesAffectingAccessibilityHint {

	return [NSSet setWithObject:@"title"];

}

- (NSString *) accessibilityHint {

	return self.title;

}

+ (NSSet *) keyPathsForValuesAffectingAccessibilityLabel {

	return [NSSet setWithObject:@"text"];

}

- (NSString *) accessibilityValue {

	return self.text;

}

- (CGSize) sizeThatFits:(CGSize)size {

	if (!self.label)
		[self layoutSubviews];
	
	CGSize delta = (CGSize){
		CGRectGetWidth(self.bounds) - CGRectGetWidth(self.label.bounds),
		CGRectGetHeight(self.bounds) - CGRectGetHeight(self.label.bounds),
	};
	
	CGSize returnedLabelSize = [self.label sizeThatFits:(CGSize){
		size.width - delta.width,
		size.height - delta.height
	}];
	
	CGSize returnedSize = (CGSize){
		ceilf(returnedLabelSize.width + delta.width),
		ceilf(returnedLabelSize.height + delta.height)
	};
	
	return returnedSize;

}


- (void) dealloc {

	[self irRemoveObserverBlocksForKeyPath:@"suggestedStyle"];
	
	[preview release];

	[titleFont release];
	[titleColor release];
	[titlePlaceholder release];
	[titlePlaceholderColor release];
	
	[providerNameFont release];
	[providerNameColor release];
	[providerNamePlaceholder release];
	[providerNamePlaceholderColor release];
	
	[textFont release];
	[textColor release];
	[textPlaceholder release];
	[textPlaceholderColor release];
	
	[imageView release];
	[label release];
	
	[backgroundView release];

	[super dealloc];

}

@end
