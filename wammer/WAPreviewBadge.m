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

@property (nonatomic, readwrite, retain) UIImage *image;
@property (nonatomic, readwrite, retain) NSString *title;
@property (nonatomic, readwrite, retain) NSString *text;
@property (nonatomic, readwrite, retain) NSURL *link;

- (WAPreviewBadgeStyle) suggestedStyle;

@property (nonatomic, readwrite, retain) UIImageView *imageView;
@property (nonatomic, readwrite, retain) IRLabel *label;

@property (nonatomic, readwrite, assign) BOOL needsTextUpdate;

- (void) updateText;
- (void) setNeedsTextUpdate;

@end


@implementation WAPreviewBadge
@synthesize style;
@synthesize image, title, text, link;
@synthesize imageView, label;
@synthesize titleFont, titleColor, textFont, textColor;
@synthesize backgroundView;
@synthesize minimumAcceptibleFullFrameAspectRatio;
@synthesize preview;
@synthesize needsTextUpdate;

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

- (void) waSharedInit {

	self.titleFont = [UIFont fontWithName:@"Sansus Webissimo" size:32.0f];
	self.titleColor = [UIColor colorWithRed:0 green:0 blue:0.45f alpha:1.0f];
	self.textFont = [UIFont fontWithName:@"Palatino" size:16.0f];
	self.textColor = [UIColor blackColor];
	
	self.backgroundColor = nil;
	self.opaque = NO;
	
	self.backgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
	self.backgroundView.opaque = NO;
	self.backgroundView.backgroundColor = nil;
	self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	self.minimumAcceptibleFullFrameAspectRatio = 0.85f;
	
	UIView *innerBackgroundView = [[[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.backgroundView.bounds, (UIEdgeInsets){ -4, -4, -4, -4 })] autorelease];
	innerBackgroundView.layer.contents = (id)[UIImage imageNamed:@"WAPreviewBadge"].CGImage;
	innerBackgroundView.layer.contentsCenter = (CGRect){ 10.0/24.0, 10.0/24.0, 4.0/24.0, 4.0/24.0 };
	innerBackgroundView.opaque = NO;
	innerBackgroundView.backgroundColor = nil;
	innerBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.backgroundView addSubview:innerBackgroundView];
	
	[self setNeedsLayout];

}

- (void) setBackgroundView:(UIView *)newBackgroundView {

	if (newBackgroundView == backgroundView)
		return;
	
	[backgroundView removeFromSuperview];
	[backgroundView release];
	backgroundView = [newBackgroundView retain];
	[self addSubview:backgroundView];
	
	[self setNeedsLayout];

}

- (void) setImage:(UIImage *)newImage {

	if (image == newImage)
		return;

	[self willChangeValueForKey:@"image"];
	[image release];
	image = [newImage retain];
	[self didChangeValueForKey:@"image"];
	
	[self setNeedsLayout];

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
	
	[self willChangeValueForKey:@"style"];
	style = newStyle;
	[self didChangeValueForKey:@"style"];
	
	[self setNeedsLayout];

}

- (void) layoutSubviews {

	[super layoutSubviews];
		
	self.backgroundView.frame = self.bounds;
	
	WAPreviewBadgeStyle const usedStyle = (self.style != WAPreviewBadgeAutomaticStyle) ? self.style : [self suggestedStyle];
	
	BOOL needsImageView = NO, needsLabel = NO;
	
	switch (usedStyle) {
		case WAPreviewBadgeImageAndTextStyle: {
			needsImageView = YES;
			needsLabel = YES;
			break;
		}
		case WAPreviewBadgeImageOnlyStyle: {
			needsImageView = YES;
			needsLabel = NO;
			break;
		}
		case WAPreviewBadgeTextOnlyStyle: {
			needsImageView = NO;
			needsLabel = YES;
			break;
		}
		case WAPreviewBadgeTextOverImageStyle: {
			needsImageView = YES;
			needsLabel = YES;
		}
	}
	
	if (needsImageView) {
		if (!self.imageView) {
			self.imageView = [[[WAImageView alloc] initWithImage:nil] autorelease];
			self.imageView.contentMode = UIViewContentModeScaleAspectFit;
			self.imageView.clipsToBounds = YES;
			
			[self addSubview:self.imageView];
		}
	} else {
		[self.imageView removeFromSuperview];
		self.imageView = nil;
	}
	
	if (needsLabel) {
		if (!self.label) {
			self.label = [[[IRLabel alloc] init] autorelease];
			self.label.backgroundColor = nil;
			self.label.opaque = NO;
			self.label.userInteractionEnabled = YES;
			self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
			[self addSubview:self.label];
		}
	} else {
		[self.label removeFromSuperview];
		self.label = nil;
	}
	
	
	if (needsTextUpdate)
		[self updateText];
	
	if (self.image)
		self.imageView.image = self.image;
	
	switch (usedStyle) {
		case WAPreviewBadgeImageAndTextStyle: {
		
			CGRect usableRect = CGRectStandardize(UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8 }));
			CGRect imageRect = IRCGSizeGetCenteredInRect((CGSize){
				CGRectGetHeight(self.bounds),
				CGRectGetHeight(self.bounds)
			}, usableRect, 0, YES);
			imageRect.origin.x = 8;
			imageRect.origin.y = 8;
			
			CGRect actualImageRect = IRCGRectAlignToRect(
				IRCGSizeGetCenteredInRect((CGSize) {
					self.imageView.image.size.width * 128,
					self.imageView.image.size.height * 128
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
			
			break;
			
		}
		
		case WAPreviewBadgeImageOnlyStyle:
		case WAPreviewBadgeTextOnlyStyle: {
		
			self.imageView.frame = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8 });
			self.label.frame = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8 });
			break;
			
		}
		
		case WAPreviewBadgeTextOverImageStyle: {
		
			self.imageView.frame = self.bounds;
			
			if (![self.imageView.subviews count]) {
			
				UIView *overlay = [[[UIView alloc] initWithFrame:self.imageView.bounds] autorelease];
				overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
				overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
				
				[self.imageView addSubview:overlay];
			
			}
			
			CGRect usableLabelFrame = CGRectInset(self.bounds, 16, 12);
			
			self.label.frame = usableLabelFrame;
			self.label.backgroundColor = nil;
			
			self.imageView.contentMode = UIViewContentModeScaleAspectFill;
			
			self.titleFont = [UIFont boldSystemFontOfSize:24.0f];
			self.titleColor = [UIColor whiteColor];
			self.textFont = [UIFont systemFontOfSize:18.0f];
			self.textColor = [UIColor whiteColor];
			
			[self bringSubviewToFront:self.label];
			
			break;
		
		}
		
		default: {
		
			NSParameterAssert(NO);
		
		}
		
	}

}

- (void) setPreview:(WAPreview *)newPreview {

	if (preview == newPreview)
		return;

	[self willChangeValueForKey:@"preview"];
	
	[preview.graphElement removeObserver:self forKeyPath:@"thumbnail"];
	[preview release];
	[newPreview.graphElement addObserver:self forKeyPath:@"thumbnail" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
	preview = [newPreview retain];
	
	[self didChangeValueForKey:@"preview"];
	
	self.image = preview.graphElement.thumbnail;
	self.link = preview.graphElement.url ? [NSURL URLWithString:preview.graphElement.url] : nil;
	self.title = preview.graphElement.title;
	self.text = preview.graphElement.text;
	
	self.accessibilityLabel = @"Preview Badge";
	self.accessibilityHint = preview.graphElement.title;
	self.accessibilityValue = preview.graphElement.text;
	
	[self setNeedsTextUpdate];
	[self setNeedsLayout];

}

- (void) setTitle:(NSString *)newTitle {

	if (title == newTitle)
		return;

	[self willChangeValueForKey:@"title"];
	
	[title release];
	title = [newTitle retain];
	
	[self didChangeValueForKey:@"title"];

	[self setNeedsTextUpdate];

}

- (void) setTitleColor:(UIColor *)newTitleColor {

	if (titleColor == newTitleColor)
		return;

	[self willChangeValueForKey:@"titleColor"];
	
	[titleColor release];
	titleColor = [newTitleColor retain];
	
	[self didChangeValueForKey:@"titleColor"];

	[self setNeedsTextUpdate];

}

- (void) setTitleFont:(UIFont *)newTitleFont {

	if (titleFont == newTitleFont)
		return;
		
	[self willChangeValueForKey:@"titleFont"];
	
	[titleFont release];
	titleFont = [newTitleFont retain];
	
	[self didChangeValueForKey:@"titleFont"];

	[self setNeedsTextUpdate];

}

- (void) setText:(NSString *)newText {

	if (text == newText)
		return;
	
	[self willChangeValueForKey:@"text"];
	
	[text release];
	text = [newText retain];
	
	[self didChangeValueForKey:@"text"];
		
	[self setNeedsTextUpdate];

}

- (void) setTextColor:(UIColor *)newTextColor {

	if (textColor == newTextColor)
		return;
	
	[self willChangeValueForKey:@"textColor"];
	
	[textColor release];
	textColor = [newTextColor retain];
	
	[self didChangeValueForKey:@"textColor"];

	[self setNeedsTextUpdate];

}

- (void) setTextFont:(UIFont *)newTextFont {

	if (textFont == newTextFont)
		return;
	
	[self willChangeValueForKey:@"textFont"];
	
	[textFont release];
	textFont = [newTextFont retain];
	
	[self didChangeValueForKey:@"textFont"];

	[self setNeedsTextUpdate];

}

- (void) setNeedsTextUpdate {

	needsTextUpdate = YES;

	[self setNeedsLayout];

}

- (void) updateText {

	needsTextUpdate = NO;

	if (self.title || self.text) {
	
		NSDictionary *titleAttributes = [[NSAttributedString irAttributesForFont:self.titleFont color:self.titleColor] irDictionaryByMergingWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
			(id)[self.titleFont irFixedLineHeightParagraphStyle], kCTParagraphStyleAttributeName,
		nil]];
		NSDictionary *contentAttributes = [[NSAttributedString irAttributesForFont:self.textFont color:self.textColor] irDictionaryByMergingWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
			(id)[self.textFont irFixedLineHeightParagraphStyle], kCTParagraphStyleAttributeName,
		nil]];
		
		if (self.link)
			titleAttributes = [titleAttributes irDictionaryBySettingObject:self.link forKey:kIRTextLinkAttribute];
		
		NSMutableAttributedString *realContentString = [[[NSMutableAttributedString alloc] initWithString:@"" attributes:nil] autorelease];
		
		if (self.title) {
						
			NSMutableAttributedString *titleAttributedString = [[[NSMutableAttributedString alloc] initWithString:self.title attributes:titleAttributes] autorelease];

			[realContentString appendAttributedString:titleAttributedString];
			[realContentString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n" attributes:nil] autorelease]];

		}
		
		if (self.text) {
			
			[realContentString appendAttributedString:[[[NSAttributedString alloc] initWithString:self.text attributes:contentAttributes] autorelease]];
			
		}
		
		self.label.attributedText = realContentString;
	
	}

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

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	NSLog(@"%s %@ %@ %@ %@", __PRETTY_FUNCTION__, keyPath, object, change, context);

}

- (void) dealloc {

	[preview.graphElement removeObserver:self forKeyPath:@"thumbnail"];
	[preview release];

	[image release];
	[title release];
	[text release];
	[link release];
	
	[imageView release];
	[label release];
	
	[backgroundView release];

	[super dealloc];

}

@end
