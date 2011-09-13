//
//  WAPreviewBadge.m
//  wammer-iOS
//
//  Created by Evadne Wu on 9/13/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

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

	UIView *backgroundView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WAPreviewBadge"]] autorelease];
	backgroundView.frame = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ -4, -4, -4, -4 });
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	backgroundView.layer.contentsCenter = (CGRect){ 10.0/24.0, 10.0/24.0, 4./24., 4.0/24.0 };
	backgroundView.opaque = NO;
	backgroundView.backgroundColor = nil;
	backgroundView.alpha = 0.25f;
	[self addSubview:backgroundView];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
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
	
	if (self.image)
		self.imageView.image = self.image;
	
	if (self.title || self.text) {
	
		NSDictionary *titleAttributes = [NSAttributedString irAttributesForFont:[UIFont boldSystemFontOfSize:20.0f] color:[UIColor colorWithRed:0 green:0 blue:0.45f alpha:1.0f]];
		NSDictionary *contentAttributes = [NSAttributedString irAttributesForFont:[UIFont systemFontOfSize:18.0f] color:[UIColor blackColor]];
		
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
		
			CGRect imageRect = (CGRect){
				16, 16,
				CGRectGetHeight(self.bounds) - 32,
				CGRectGetHeight(self.bounds) - 32
			};
			
			
			self.imageView.frame = IRCGRectAlignToRect(
				IRCGSizeGetCenteredInRect((CGSize) {
					self.imageView.image.size.width * 16,
					self.imageView.image.size.height * 16
				}, imageRect, 0.0f, YES),
				imageRect,
				//	UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ 8, 8, 8, 8}), 
				irTopLeft, 
				YES
			);
			
			CGRect labelRect, tempRect;
			CGRectDivide(self.bounds, &tempRect, &labelRect, imageRect.size.width, CGRectMinXEdge);
			labelRect.origin.x += 32;
			labelRect.origin.y += 24;
			labelRect.size.height -= 48;
			labelRect.size.width -= 48;
			
			self.label.frame = labelRect;
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

- (void) dealloc {

	[image release];
	[title release];
	[text release];
	[link release];
	
	[imageView release];
	[label release];

	[super dealloc];

}

@end
