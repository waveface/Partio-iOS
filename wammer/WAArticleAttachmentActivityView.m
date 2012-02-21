//
//  WAArticleAttachmentActivityView.m
//  wammer
//
//  Created by Evadne Wu on 2/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleAttachmentActivityView.h"
#import "CGGeometry+IRAdditions.h"
#import "UIKit+IRAdditions.h"
#import "WADefines.h"

@interface WAArticleAttachmentActivityView ()

@property (nonatomic, readwrite, retain) UIButton *button;
@property (nonatomic, readwrite, retain) IRActivityIndicatorView *spinner;
- (void) updateAccordingToCurrentStyle;

@property (nonatomic, readwrite, retain) NSMutableDictionary *stylesToTitles;

@end

@implementation WAArticleAttachmentActivityView
@synthesize button, spinner, style, onTap, stylesToTitles;

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)	
		return nil;
	
	button = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	button.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	
	[button setImageEdgeInsets:(UIEdgeInsets){ 0, 0, 0, 0 }];
	[button setTitleEdgeInsets:(UIEdgeInsets){ 0, 10, 0, 0 }];
	[button setTitleColor:[UIColor colorWithRed:114.0/255.0 green:49.0/255.0 blue:23.0/255.0 alpha:1] forState:UIControlStateNormal];
	
	[button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:button];
	
	spinner = [[IRActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self addSubview:spinner];
	
	style = WAArticleAttachmentActivityViewDefaultStyle;
	
	[self setNeedsLayout];
	[self updateAccordingToCurrentStyle];

	return self;
	
}

- (void) layoutSubviews {

	[super layoutSubviews];

	button.frame = self.bounds;
	
	if (button.imageView)
		spinner.center = [spinner.superview convertPoint:button.imageView.center fromView:button.imageView.superview];
	else 
		spinner.center = irCGRectAnchor(self.bounds, irCenter, YES);

}

- (void) setStyle:(WAArticleAttachmentActivityViewStyle)newStyle {

	if (style == newStyle)
		return;
	
	[self willChangeValueForKey:@"style"];
	
	style = newStyle;
	
	[self updateAccordingToCurrentStyle];
	
	[self didChangeValueForKey:@"style"];

}

	
- (void) updateAccordingToCurrentStyle {

	BOOL const isBusy = (style == WAArticleAttachmentActivityViewSpinnerStyle);

	spinner.animating = isBusy;
	button.hidden = isBusy;
	
	switch (style) {
	
		case WAArticleAttachmentActivityViewAttachmentsStyle: {
			[button setImage:WABarButtonImageFromImageNamed(@"WAAttachmentGlyph") forState:UIControlStateNormal];
			break;
		}
		
		case WAArticleAttachmentActivityViewLinkStyle: {
			[button setImage:WABarButtonImageFromImageNamed(@"WALinkGlyph") forState:UIControlStateNormal];
			break;
		}
		
		default:
			break;
		
	};
	
	[button setTitle:[self titleForStyle:style] forState:UIControlStateNormal];
	
}

- (IBAction) handleButtonTap:(id)sender {

	if (self.onTap)
		self.onTap();

}

- (NSMutableDictionary *) stylesToTitles {

	if (stylesToTitles)
		return stylesToTitles;
	
	stylesToTitles = [[NSMutableDictionary dictionary] retain];
	return stylesToTitles;

}

- (void) setTitle:(NSString *)title forStyle:(WAArticleAttachmentActivityViewStyle)aStyle {

	[self.stylesToTitles setObject:title forKey:[NSValue valueWithBytes:&aStyle objCType:@encode(__typeof__(aStyle))]];	
	[self updateAccordingToCurrentStyle];

}

- (NSString *) titleForStyle:(WAArticleAttachmentActivityViewStyle)aStyle {

	return [self.stylesToTitles objectForKey:[NSValue valueWithBytes:&aStyle objCType:@encode(__typeof__(aStyle))]];

}

- (void) dealloc {

	[button release];
	[spinner release];
	[onTap release];
	
	[stylesToTitles release];
	
	[super dealloc];

}

@end
