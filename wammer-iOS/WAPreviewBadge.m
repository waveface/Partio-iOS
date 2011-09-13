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
#import "IRLabel.h"
#import "CoreText+IRAdditions.h"
#import "CGGeometry+IRAdditions.h"


#ifndef __WAPreviewBadge__
#define __WAPreviewBadge__

typedef enum {
	WAPreviewBadgeImageAndTextStyle = 0,
	WAPreviewBadgeTextOnlyStyle,
	WAPreviewBadgeImageOnlyStyle
} WAPreviewBadgeStyle;

#endif

@interface WAPreviewBadge ()

- (void) waSharedInit;

@property (nonatomic, readwrite, retain) UIImageView *imageView;
@property (nonatomic, readwrite, retain) IRLabel *label;

@end


@implementation WAPreviewBadge
@synthesize image, title, text, link;
@synthesize imageView, label;
@synthesize titleFont, titleColor, textFont, textColor;
@synthesize backgroundView;
@synthesize minimumAcceptibleFullFrameAspectRatio;

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

	self.titleFont = [UIFont boldSystemFontOfSize:18.0f];
	self.titleColor = [UIColor colorWithRed:0 green:0 blue:0.45f alpha:1.0f];
	self.textFont = [UIFont systemFontOfSize:16.0f];
	self.textColor = [UIColor blackColor];
	
	self.backgroundColor = nil;
	self.opaque = NO;
	
	self.backgroundView = [[[UIView alloc] initWithFrame:self.bounds] autorelease];
	self.backgroundView.opaque = NO;
	self.backgroundView.backgroundColor = nil;
	self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	self.minimumAcceptibleFullFrameAspectRatio = 0.85f;
	
	UIView *innerBackgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WAPreviewBadge"]] autorelease];
	innerBackgroundView.layer.contentsCenter = (CGRect){ 10.0/24.0, 10.0/24.0, 4./24., 4.0/24.0 };
	innerBackgroundView.opaque = NO;
	innerBackgroundView.backgroundColor = nil;
	innerBackgroundView.frame = UIEdgeInsetsInsetRect(self.backgroundView.bounds, (UIEdgeInsets){ -4, -4, -4, -4 });
	innerBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.backgroundView addSubview:innerBackgroundView];

#if 0
	
	innerBackgroundView.alpha = 0.25f;
	innerBackgroundView.layer.borderColor = [UIColor redColor].CGColor;
	innerBackgroundView.layer.borderWidth = 2.0f;
		
#endif

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

- (void) layoutSubviews {

	[super layoutSubviews];
	
	self.backgroundView.frame = self.bounds;
	
	WAPreviewBadgeStyle style = WAPreviewBadgeImageAndTextStyle;
	
	if (!self.title && !self.text && self.image)
		style = WAPreviewBadgeImageOnlyStyle;
	else if ((self.title || self.text) && !self.image)
		style = WAPreviewBadgeTextOnlyStyle;
		
	BOOL needsImageView = NO, needsLabel = NO;
	
	switch (style) {
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
	}
	
	if (needsImageView) {
		if (!self.imageView) {
			self.imageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
			self.imageView.backgroundColor = nil;
			self.imageView.opaque = NO;
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
			[self addSubview:self.label];
		}
	} else {
		[self.label removeFromSuperview];
		self.label = nil;
	}
	
#if 0
	
	self.layer.borderColor = [UIColor greenColor].CGColor;
	self.layer.borderWidth = 2.0f;
	
	self.label.layer.borderColor = [UIColor redColor].CGColor;
	self.label.layer.borderWidth = 2.0f;
	
#endif
	
	if (self.image)
		self.imageView.image = self.image;
	
	if (self.title || self.text) {
	
		NSDictionary *titleAttributes = [NSAttributedString irAttributesForFont:self.titleFont color:self.titleColor];
		NSDictionary *contentAttributes = [NSAttributedString irAttributesForFont:self.textFont color:self.textColor];
		
		if (self.link)
			titleAttributes = [titleAttributes irDictionaryBySettingObject:self.link forKey:kIRTextLinkAttribute];
		
		NSMutableAttributedString *realContentString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
		
		if (self.title) {
			[realContentString appendAttributedString:[[[NSAttributedString alloc] initWithString:self.title attributes:titleAttributes] autorelease]];
			[realContentString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n \n" attributes:[NSAttributedString irAttributesForFont:[UIFont boldSystemFontOfSize:12.0f] color:nil]] autorelease]];
		}
		
		if (self.text)
			[realContentString appendAttributedString:[[[NSAttributedString alloc] initWithString:self.text attributes:contentAttributes] autorelease]];
		
		self.label.attributedText = realContentString;
	
	}
	
	
	switch (style) {
		case WAPreviewBadgeImageAndTextStyle: {
		
			CGRect usableRect = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8 });
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
			
			self.imageView.layer.borderColor = [UIColor redColor].CGColor;
			self.imageView.layer.borderWidth = 1.0f;
			
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
				self.imageView.layer.borderColor = [UIColor blueColor].CGColor;
			} else {
				self.imageView.contentMode = UIViewContentModeScaleAspectFill;
				self.imageView.layer.borderColor = [UIColor greenColor].CGColor;
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
		
	}

}

- (void) configureWithPreview:(WAPreview *)aPreview {

	self.image = [UIImage imageWithContentsOfFile:aPreview.graphElement.thumbnailFilePath];
	self.link = aPreview.graphElement.url ? [NSURL URLWithString:aPreview.graphElement.url] : nil;
	self.title = ((^ {
		
		NSString *graphTitle = aPreview.graphElement.title;
		if ([[graphTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length])
			return graphTitle;
			
		return nil;
		
	})());
	
	self.text = ((^ {
		
		NSString *graphText = aPreview.graphElement.text;
		if ([[graphText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length])
			return graphText;
			
		return nil;
		
	})());
	
	[self setNeedsLayout];
	[self.label setNeedsDisplay];

}

- (void) dealloc {

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
