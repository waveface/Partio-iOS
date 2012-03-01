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

	NSParameterAssert([NSThread isMainThread]);

	self = [super initWithFrame:frame];
	if (!self)	
		return nil;
	
	button = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
	button.contentHorizontalAlignment = UIControlContentVerticalAlignmentCenter;
	button.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
	button.titleLabel.shadowColor = [UIColor blackColor];
	button.titleLabel.shadowOffset = CGSizeMake(0, -1);
	
	[button setImageEdgeInsets:(UIEdgeInsets){ 0, 0, 0, 0 }];
	
	#ifdef GOOD_DESIGN
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
		button.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
		[button setTitleEdgeInsets:(UIEdgeInsets){ 0, 10, 0, 0 }];
		[button setTitleColor:[UIColor colorWithRed:114.0/255.0 green:49.0/255.0 blue:23.0/255.0 alpha:1] forState:UIControlStateNormal];
	#endif

	[button addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	
	[button setBackgroundImage:[[UIImage imageNamed:@"addButton"]resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)] forState:UIControlStateNormal];
	[button setBackgroundImage:[[UIImage imageNamed:@"addHighlight"]resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)] forState:UIControlStateHighlighted];
	[self addSubview:button];
	
	spinner = [[IRActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self addSubview:spinner];
	
	style = WAArticleAttachmentActivityViewDefaultStyle;
	
	[self setNeedsLayout];
	[self updateAccordingToCurrentStyle];

	return self;
	
}

- (void) layoutSubviews {

	NSParameterAssert([NSThread isMainThread]);
	
	[super layoutSubviews];

	button.frame = self.bounds;
	
	if (button.imageView)
		spinner.center = [spinner.superview convertPoint:button.imageView.center fromView:button.imageView.superview];
	else 
		spinner.center = irCGRectAnchor(self.bounds, irCenter, YES);

}

- (void) setStyle:(WAArticleAttachmentActivityViewStyle)newStyle {

	NSParameterAssert([NSThread isMainThread]);

	if (style == newStyle)
		return;
	
	[self willChangeValueForKey:@"style"];
	
	style = newStyle;
	
	[self updateAccordingToCurrentStyle];
	
	[self didChangeValueForKey:@"style"];

}

	
- (void) updateAccordingToCurrentStyle {

	NSParameterAssert([NSThread isMainThread]);

	BOOL const isBusy = (style == WAArticleAttachmentActivityViewSpinnerStyle);

	spinner.animating = isBusy;
	button.hidden = isBusy;
	
	#ifdef GOOD_DESIGN
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
	#endif
	
	[button setTitle:[self titleForStyle:style] forState:UIControlStateNormal];
	
}

- (IBAction) handleButtonTap:(id)sender {

	NSParameterAssert([NSThread isMainThread]);

	if (self.onTap)
		self.onTap();

}

- (NSMutableDictionary *) stylesToTitles {

	NSParameterAssert([NSThread isMainThread]);

	if (stylesToTitles)
		return stylesToTitles;
	
	stylesToTitles = [[NSMutableDictionary dictionary] retain];
	return stylesToTitles;

}

- (void) setTitle:(NSString *)title forStyle:(WAArticleAttachmentActivityViewStyle)aStyle {

	NSParameterAssert([NSThread isMainThread]);

	[self.stylesToTitles setObject:title forKey:[NSValue valueWithBytes:&aStyle objCType:@encode(__typeof__(aStyle))]];	
	[self updateAccordingToCurrentStyle];

}

- (NSString *) titleForStyle:(WAArticleAttachmentActivityViewStyle)aStyle {

	NSParameterAssert([NSThread isMainThread]);

	return [self.stylesToTitles objectForKey:[NSValue valueWithBytes:&aStyle objCType:@encode(__typeof__(aStyle))]];

}

- (void) dealloc {

	NSParameterAssert([NSThread isMainThread]);

	[button release];
	[spinner release];
	[onTap release];
	
	[stylesToTitles release];
	
	[super dealloc];

}

@end
