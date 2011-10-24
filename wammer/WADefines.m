//
//  WADefines.m
//  wammer
//
//  Created by Evadne Wu on 10/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"

#import "IRBorder.h"
#import "IRShadow.h"
#import "IRBarButtonItem.h"

NSString * const kWARemoteEndpointURL = @"WARemoteEndpointURL";
NSString * const kWALastAuthenticatedUserTokenKeychainItem = @"WALastAuthenticatedUserTokenKeychainItem";
NSString * const kWALastAuthenticatedUserIdentifier = @"WALastAuthenticatedUserIdentifier";

static IRBorder *kWADefaultBarButtonBorder;
static IRShadow *kWADefaultBarButtonInnerShadow;
static IRShadow *kWADefaultBarButtonShadow;

static UIFont *kWADefaultBarButtonTitleFont;
static UIColor *kWADefaultBarButtonTitleColor;
static IRShadow *kWADefaultBarButtonTitleShadow;

static UIColor *kWADefaultBarButtonGradientFromColor;
static UIColor *kWADefaultBarButtonGradientToColor;
static NSArray *kWADefaultBarButtonGradientColors;
static UIColor *kWADefaultBarButtonBackgroundColor;

static UIColor *kWADefaultBarButtonHighlightedGradientFromColor;
static UIColor *kWADefaultBarButtonHighlightedGradientToColor;
static NSArray *kWADefaultBarButtonHighlightedGradientColors;
static UIColor *kWADefaultBarButtonHighlightedBackgroundColor;

void kWADefaultBarButtonInitialize (void);






void kWADefaultBarButtonInitialize (void) {

	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		
		kWADefaultBarButtonBorder = [IRBorder borderForEdge:IREdgeNone withType:IRBorderTypeInset width:1 color:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5]];
		kWADefaultBarButtonInnerShadow = [IRShadow shadowWithColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.55] offset:(CGSize){ 0, 1 } spread:2];
		kWADefaultBarButtonShadow = [IRShadow shadowWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1] offset:(CGSize){ 0, 1 } spread:1];
		
		kWADefaultBarButtonTitleFont = [UIFont boldSystemFontOfSize:12];
		kWADefaultBarButtonTitleColor = [UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1];
		kWADefaultBarButtonTitleShadow = [IRShadow shadowWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:.35] offset:(CGSize){ 0, 1 } spread:0];

		kWADefaultBarButtonGradientFromColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1];
		kWADefaultBarButtonGradientToColor = [UIColor colorWithRed:.5 green:.5 blue:.5 alpha:1];
		
		kWADefaultBarButtonGradientColors = [NSArray arrayWithObjects:(id)kWADefaultBarButtonGradientFromColor.CGColor, (id)kWADefaultBarButtonGradientToColor.CGColor, nil];
		
		kWADefaultBarButtonBackgroundColor = nil;

		kWADefaultBarButtonHighlightedGradientFromColor = [kWADefaultBarButtonGradientFromColor colorWithAlphaComponent:.95];
		kWADefaultBarButtonHighlightedGradientToColor = [kWADefaultBarButtonGradientToColor colorWithAlphaComponent:.95];
		kWADefaultBarButtonHighlightedGradientColors = [NSArray arrayWithObjects:(id)kWADefaultBarButtonHighlightedGradientFromColor.CGColor, (id)kWADefaultBarButtonHighlightedGradientToColor.CGColor, nil];
		kWADefaultBarButtonHighlightedBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
		
		[kWADefaultBarButtonBorder retain];
		[kWADefaultBarButtonInnerShadow retain];
		[kWADefaultBarButtonShadow retain];

		[kWADefaultBarButtonTitleFont retain];
		[kWADefaultBarButtonTitleColor retain];
		[kWADefaultBarButtonTitleShadow retain];

		[kWADefaultBarButtonGradientFromColor retain];
		[kWADefaultBarButtonGradientToColor retain];
		[kWADefaultBarButtonGradientColors retain];
		[kWADefaultBarButtonBackgroundColor retain];

		[kWADefaultBarButtonHighlightedGradientFromColor retain];
		[kWADefaultBarButtonHighlightedGradientToColor retain];
		[kWADefaultBarButtonHighlightedGradientColors retain];
		[kWADefaultBarButtonHighlightedBackgroundColor retain];

	});

}


void WARegisterUserDefaults () {

	NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"WADefaults" withExtension:@"plist"];
	NSData *defaultsData = [NSData dataWithContentsOfMappedFile:[defaultsURL path]];
	NSDictionary *defaultsObject = [NSPropertyListSerialization propertyListFromData:defaultsData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsObject];

}


IRBarButtonItem * WAStandardBarButtonItem (NSString *labelText, void(^aBlock)(void)) {

	kWADefaultBarButtonInitialize();

	UIImage *normalImage = [IRBarButtonItem buttonImageForStyle:IRBarButtonItemStyleBordered withTitle:labelText font:kWADefaultBarButtonTitleFont color:kWADefaultBarButtonTitleColor shadow:kWADefaultBarButtonTitleShadow backgroundColor:kWADefaultBarButtonBackgroundColor gradientColors:kWADefaultBarButtonGradientColors innerShadow:kWADefaultBarButtonInnerShadow border:kWADefaultBarButtonBorder shadow:kWADefaultBarButtonShadow];
	
	UIImage *highlightedImage = [IRBarButtonItem buttonImageForStyle:IRBarButtonItemStyleBordered withTitle:labelText font:kWADefaultBarButtonTitleFont color:kWADefaultBarButtonTitleColor shadow:kWADefaultBarButtonTitleShadow backgroundColor:kWADefaultBarButtonHighlightedBackgroundColor gradientColors:kWADefaultBarButtonHighlightedGradientColors innerShadow:kWADefaultBarButtonInnerShadow border:kWADefaultBarButtonBorder shadow:kWADefaultBarButtonShadow];

	__block IRBarButtonItem *item = [IRBarButtonItem itemWithCustomImage:normalImage highlightedImage:highlightedImage];
	
	if (aBlock)
		item.block = aBlock;

	return item;

}

IRBarButtonItem * WABackBarButtonItem (NSString *labelText, void(^aBlock)(void)) {

	kWADefaultBarButtonInitialize();
	
	UIImage *normalImage = [IRBarButtonItem buttonImageForStyle:IRBarButtonItemStyleBack withTitle:labelText font:kWADefaultBarButtonTitleFont color:kWADefaultBarButtonTitleColor shadow:kWADefaultBarButtonTitleShadow backgroundColor:kWADefaultBarButtonBackgroundColor gradientColors:kWADefaultBarButtonGradientColors innerShadow:kWADefaultBarButtonInnerShadow border:kWADefaultBarButtonBorder shadow:kWADefaultBarButtonShadow];
	
	UIImage *highlightedImage = [IRBarButtonItem buttonImageForStyle:IRBarButtonItemStyleBack withTitle:labelText font:kWADefaultBarButtonTitleFont color:kWADefaultBarButtonTitleColor shadow:kWADefaultBarButtonTitleShadow backgroundColor:kWADefaultBarButtonHighlightedBackgroundColor gradientColors:kWADefaultBarButtonHighlightedGradientColors innerShadow:kWADefaultBarButtonInnerShadow border:kWADefaultBarButtonBorder shadow:kWADefaultBarButtonShadow];

	__block IRBarButtonItem *item = [IRBarButtonItem itemWithCustomImage:normalImage highlightedImage:highlightedImage];
	
	if (aBlock)
		item.block = aBlock;

	return item;

}
