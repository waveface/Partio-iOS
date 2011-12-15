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

#import "UIImage+IRAdditions.h"

NSString * const kWAAdvancedFeaturesEnabled = @"WAAdvancedFeaturesEnabled";

BOOL WAAdvancedFeaturesEnabled (void) {
  return [[NSUserDefaults standardUserDefaults] boolForKey:kWAAdvancedFeaturesEnabled];
};


NSString * const kWARemoteEndpointURL = @"WARemoteEndpointURL";
NSString * const kWARemoteEndpointVersion = @"WARemoteEndpointVersion";
NSString * const kWARemoteEndpointCurrentVersion = @"WARemoteEndpointCurrentVersion";
NSString * const kWALastAuthenticatedUserTokenKeychainItem = @"WALastAuthenticatedUserTokenKeychainItem";
NSString * const kWALastAuthenticatedUserPrimaryGroupIdentifier = @"WALastAuthenticatedUserPrimaryGroupIdentifier";
NSString * const kWALastAuthenticatedUserIdentifier = @"WALastAuthenticatedUserIdentifier";
NSString * const kWAUserRegistrationUsesWebVersion = @"WAUserRegistrationUsesWebVersion";
NSString * const kWAUserRegistrationEndpointURL = @"WAUserRegistrationEndpointURL";
NSString * const kWAUserRequiresReauthentication = @"WAUserRequiresReauthentication";
NSString * const kWAUserPasswordResetEndpointURL = @"WAUserPasswordResetEndpointURL";
NSString * const kWAAlwaysAllowExpensiveRemoteOperations = @"WAAlwaysAllowExpensiveRemoteOperations";
NSString * const kWAAlwaysDenyExpensiveRemoteOperations = @"WAAlwaysDenyExpensiveRemoteOperations";
NSString * const kWADebugAutologinUserIdentifier = @"WADebugAutologinUserIdentifier";
NSString * const kWADebugAutologinUserPassword = @"WADebugAutologinUserPassword";
NSString * const kWACrashReportRecipients = @"WACrashReportRecipients";

NSString * const kWACompositionSessionRequestedNotification = @"WACompositionSessionRequestedNotification";
NSString * const kWAApplicationDidReceiveRemoteURLNotification = @"WAApplicationDidReceiveRemoteURLNotification";
NSString * const kWARemoteInterfaceReachableHostsDidChangeNotification = @"WARemoteInterfaceReachableHostsDidChangeNotification";
NSString * const kWARemoteInterfaceDidObserveAuthenticationFailureNotification = @"WARemoteInterfaceDidObserveAuthenticationFailureNotification";

NSString * const kWARemoteEndpointApplicationKeyPhone = @"ca5c3c5c-287d-5805-93c1-a6c2cbf9977c";
NSString * const kWARemoteEndpointApplicationKeyPad = @"ba15e628-44e6-51bc-8146-0611fdfa130b";

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

	[[NSUserDefaults standardUserDefaults] registerDefaults:WAPresetDefaults()];

}

NSDictionary * WAPresetDefaults () {

	NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"WADefaults" withExtension:@"plist"];
	NSData *defaultsData = [NSData dataWithContentsOfMappedFile:[defaultsURL path]];
	NSDictionary *defaultsObject = [NSPropertyListSerialization propertyListFromData:defaultsData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
	
	return defaultsObject;

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

UIButton * WAButtonForImage (UIImage *anImage) {

	//NSParameterAssert(anImage);
	UIButton *returnedButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[returnedButton setImage:anImage forState:UIControlStateNormal];
	[returnedButton setAdjustsImageWhenHighlighted:YES];
	[returnedButton setShowsTouchWhenHighlighted:YES];
	[returnedButton setContentEdgeInsets:(UIEdgeInsets){ 0, 5, 0, 0 }];
	[returnedButton sizeToFit];
	return returnedButton;
	
}

UIButton * WAToolbarButtonForImage (UIImage *anImage) {

  UIButton *button = WAButtonForImage(anImage);
  button.bounds = (CGRect){ CGPointZero, (CGSize){ 44, 44 }};
  
  return button;
  
}

UIImage * WABarButtonImageFromImageNamed (NSString *aName) {

  UIColor *fillColor;
  IRShadow *shadow;
  
  switch ([UIDevice currentDevice].userInterfaceIdiom) {
    
    case UIUserInterfaceIdiomPhone: {
      fillColor = [UIColor colorWithRed:114.0/255.0 green:49.0/255.0 blue:23.0/255.0 alpha:1];      
      shadow = [IRShadow shadowWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.35f] offset:(CGSize){ 0, 1 } spread:0];
      break;
    }

    default: {
      fillColor = [UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1];
      shadow = [IRShadow shadowWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.75f] offset:(CGSize){ 0, 1 } spread:0];
      break;
    }
  }
  
	return [[UIImage imageNamed:aName] irSolidImageWithFillColor:fillColor shadow:shadow];

}

NSString * const kWACurrentGeneratedDeviceIdentifier = @"WACurrentGeneratedDeviceIdentifier";

BOOL WADeviceIdentifierReset (void) {

	CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
	if (!uuidRef)
    return NO;
	
	NSString *uuid = [NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, uuidRef)) autorelease];
	CFRelease(uuidRef);

  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWACurrentGeneratedDeviceIdentifier];
  [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:kWACurrentGeneratedDeviceIdentifier];
  
  return [[NSUserDefaults standardUserDefaults] synchronize];

}

NSString * WADeviceIdentifier (void) {

  NSString *returnedString = [[NSUserDefaults standardUserDefaults] stringForKey:kWACurrentGeneratedDeviceIdentifier];
  if (returnedString)
    return returnedString;

  if (WADeviceIdentifierReset())
    return WADeviceIdentifier();

  return nil;

}