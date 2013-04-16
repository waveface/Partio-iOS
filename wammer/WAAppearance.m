//
//  WAAppearance.m
//  wammer
//
//  Created by Evadne Wu on 4/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAAppearance.h"
#import <UIKit/UIKit.h>
#import "UIKit+IRAdditions.h"
#import "WACalendarPickerViewController.h"
#import <BlocksKit/BlocksKit.h>

#pragma mark - UIAppearance
void WADefaultAppearance(void) {
		
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
		
		// set the appearance for all major UINavigationBar and toolbar
		UIColor *naviBgColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];

		CGSize barSize = CGSizeMake(1.0, 44.0);
		UIGraphicsBeginImageContext(barSize);
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(context, naviBgColor.CGColor);
		CGContextAddRect(context, CGRectMake(0, 0, barSize.width, barSize.height));
		CGContextFillPath(context);
		UIImage *naviBg = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		[[UINavigationBar appearance] setBackgroundImage:naviBg forBarMetrics:UIBarMetricsDefault];
	
		CGSize shadowSize = CGSizeMake(15.0, 1.0);
		UIGraphicsBeginImageContext(shadowSize);
		CGContextRef shadowContext = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(shadowContext, [UIColor colorWithRed:193/255.0 green:193/255.0 blue:193/255.0 alpha:1].CGColor);
		CGContextAddRect(shadowContext, CGRectMake(7.0, 0, 1.0, shadowSize.height));
		CGContextFillPath(shadowContext);
		UIImage *naviShadow = UIGraphicsGetImageFromCurrentImageContext();
		UIImage *naviShadowWithInsets = [naviShadow resizableImageWithCapInsets:UIEdgeInsetsMake(0, 7, 0, 7)];
		UIGraphicsEndImageContext();
		[[UINavigationBar appearance] setShadowImage:naviShadowWithInsets];
		
		NSValue *shadowOffset = [NSValue valueWithUIOffset:(UIOffset){0,0}];

		UIColor *textColor = [UIColor colorWithRed:0.30f green:0.30f blue:0.30f alpha:1];
		[[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeTextColor: textColor, UITextAttributeTextShadowOffset:shadowOffset}];

		UIColor *btnTextColor = [UIColor colorWithRed:0.45f green:0.45f blue:0.45f alpha:1];
		[[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor: btnTextColor, UITextAttributeTextShadowOffset:shadowOffset} forState:UIControlStateNormal];
		[[UIBarButtonItem appearance] setTintColor:naviBgColor];
		
		[[UIToolbar appearance] setTintColor:naviBgColor];
	
		[[UINavigationBar appearanceWhenContainedIn:[WACalendarPickerViewController class], nil] setShadowImage:[[UIImage alloc] init]];
		
}


void WAPartioDefaultAppearance(void) {
  [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
  [[UINavigationBar appearance] setTitleTextAttributes:@{@"UITextAttributeFont": [UIFont fontNamesForFamilyName:@"OpenSans_Semibold"]}];
}

#pragma mark - Origianl appearance settings
void WADefaultBarButtonInitialize (void) {

	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
	
		kWADefaultBarButtonTitleFont = [UIFont boldSystemFontOfSize:12];
		kWADefaultBarButtonBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
		kWADefaultBarButtonHighlightedBackgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
		
		kWADefaultBarButtonBorder = [IRBorder borderForEdge:IREdgeNone withType:IRBorderTypeInset width:1 color:[UIColor colorWithRed:143.0/255.0 green:60.0/255.0 blue:32.0/255.0 alpha:1]];
		kWADefaultBarButtonInnerShadow = [IRShadow shadowWithColor:[UIColor colorWithWhite:1 alpha:0.5] offset:(CGSize){ 0, 1 } spread:2];
		kWADefaultBarButtonShadow = [IRShadow shadowWithColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5] offset:(CGSize){ 0, 1 } spread:1];
		
		kWADefaultBarButtonTitleFont = [UIFont boldSystemFontOfSize:12];
		kWADefaultBarButtonTitleColor = [UIColor colorWithRed:100.0/255.0 green:43.0/255.0 blue:18.0/255.0 alpha:1];
		kWADefaultBarButtonTitleShadow = [IRShadow shadowWithColor:[UIColor colorWithWhite:1 alpha:.25] offset:(CGSize){ 0, 1 } spread:1];
		
		kWADefaultBarButtonGradientFromColor = [UIColor colorWithWhite:1 alpha:.125];
		kWADefaultBarButtonGradientToColor = [UIColor colorWithWhite:1 alpha:0];	//	.25
		kWADefaultBarButtonBackgroundColor = [UIColor colorWithWhite:0 alpha:0];	//	0.1
		
		kWADefaultBarButtonHighlightedGradientFromColor = kWADefaultBarButtonGradientFromColor;
		kWADefaultBarButtonHighlightedGradientToColor = kWADefaultBarButtonGradientToColor;
		kWADefaultBarButtonHighlightedBackgroundColor = [UIColor colorWithWhite:0 alpha:0.15];
		
		kWADefaultBarButtonGradientColors = [NSArray arrayWithObjects:(id)kWADefaultBarButtonGradientFromColor.CGColor, (id)kWADefaultBarButtonGradientToColor.CGColor, nil];
		kWADefaultBarButtonHighlightedGradientColors = [NSArray arrayWithObjects:(id)kWADefaultBarButtonHighlightedGradientFromColor.CGColor, (id)kWADefaultBarButtonHighlightedGradientToColor.CGColor, nil];
		
	});
	
}

UIBarButtonItem *WAPartioBackButton(void(^handler)(void)) {
  UIImage *backImage = [UIImage imageNamed:@"back"];
  UIButton *backButton = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, backImage.size}];
  [backButton setImage:backImage forState:UIControlStateNormal];
  [backButton addEventHandler:^(id sender) {
    if (handler)
      handler();
  } forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
  return backItem;
}

UIBarButtonItem *WAPartioToolbarNextButton(NSString *labelText, void(^aBlock)(void)) {
  UIImage *nextImage = [UIImage imageNamed:@"Btn"];
  UIButton *nextButton = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, CGSizeMake((43/nextImage.size.height)*nextImage.size.width, 43)}];
  [nextButton setBackgroundImage:nextImage forState:UIControlStateNormal];
  [nextButton setBackgroundImage:[UIImage imageNamed:@"Btn1"] forState:UIControlStateHighlighted];
  [nextButton setTitle:labelText forState:UIControlStateNormal];
  [nextButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:14.f]];
  [nextButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
  nextButton.titleLabel.textColor = [UIColor whiteColor];
  [nextButton addEventHandler:^(id sender) {
    if (aBlock)
      aBlock();
  } forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithCustomView:nextButton];
  return nextItem;
}

IRBarButtonItem * WABarButtonItem (UIImage *image, NSString *labelText, void(^aBlock)(void)) {

	IRBarButtonItem *item = nil;
	
	if (image)
		item = [IRBarButtonItem itemWithCustomImage:image highlightedImage:nil];
	else
		item = [[IRBarButtonItem alloc] initWithTitle:labelText style:UIBarButtonItemStyleBordered target:nil action:nil];
	
	if (aBlock)
		item.block = aBlock;
	
	return item;

}

IRBarButtonItem * WABarButtonItemWithButton (UIButton *aButton, void(^aBlock)(void)) {
	
	IRBarButtonItem *item = nil;
	
	if (aBlock)
		item.block = aBlock;

	if (aButton) 
		item = [IRBarButtonItem itemWithButton:aButton wiredAction:aBlock?item.block:nil];
	
	return item;
	
}

IRBarButtonItem * WABackBarButtonItem (UIImage *image, NSString *labelText, void(^aBlock)(void)) {

	IRBarButtonItem *item;
		
	item = [IRBarButtonItem itemWithCustomImage:image highlightedImage:nil];
	
	if (aBlock)
		item.block = aBlock;

	return item;

}

IRBarButtonItem * WATransparentBlackBackBarButtonItem (UIImage *itemImage, NSString *title, void(^block)(void)) {

	IRBarButtonItem *item = [[IRBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStyleBordered target:nil action:nil];
	item.block = block;
	
	UIImage * (^image)(NSString *, UIEdgeInsets) = ^ (NSString *name, UIEdgeInsets insets) {
		return [[UIImage imageNamed:name] resizableImageWithCapInsets:insets];
	};
	
	[item setBackgroundImage:image(@"UINavigationBarBlackTranslucentBack", (UIEdgeInsets){ 0, 13, 0, 5 }) forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	[item setBackgroundImage:image(@"UINavigationBarBlackTranslucentBackPressed", (UIEdgeInsets){ 0, 13, 0, 5 }) forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
	[item setBackgroundImage:image(@"UINavigationBarMiniBlackTranslucentBack", (UIEdgeInsets){ 0, 10, 0, 4 })  forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
	[item setBackgroundImage:image(@"UINavigationBarMiniBlackTranslucentBackPressed", (UIEdgeInsets){ 0, 10, 0, 4 }) forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
	
	[item setImage:[itemImage irSolidImageWithFillColor:[UIColor whiteColor] shadow:nil]];
	[item setTitle:title];
	
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

UIButton *WAToolbarButtonForImage (UIImage *anImage, NSString *aAccessbilityLabel) {

  UIButton *button = WAButtonForImage(anImage);
  button.bounds = (CGRect){ CGPointZero, (CGSize){ 44, 44 }};
  if (aAccessbilityLabel.length != 0 ){
		button.isAccessibilityElement = YES;
		button.accessibilityLabel = aAccessbilityLabel;
	}
  return button;
  
}

UIImage * WABarButtonImageFromImageNamed (NSString *aName) {

	UIColor *fillColor = [UIColor whiteColor];
	IRShadow *shadow = [IRShadow shadowWithColor:[UIColor colorWithWhite:0 alpha:0.5] offset:(CGSize){ 0, -0.5} spread:0.5];
  
	return WABarButtonImageWithOptions(aName, fillColor, shadow);

}

UIImage * WABarButtonImageWithOptions (NSString *aName, UIColor *fillColor, IRShadow *shadow) {

	UIImage *image = [UIImage imageNamed:aName];
	if (!image)
		image = IRUIKitImage(aName);
	
	NSCAssert1(image, @"Image named %@ must exist", aName);

	return [image irSolidImageWithFillColor:fillColor shadow:shadow];

};

UIView * WAStandardTitleView (void) {

	UIImageView *logotype = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WALogotype"]];
	logotype.contentMode = UIViewContentModeScaleAspectFit;
	logotype.autoresizingMask = UIViewAutoresizingNone;
 
	[logotype sizeToFit];
	
	return logotype;

}


UIView * WAStandardPostCellBackgroundView (void) {

	static UIEdgeInsets const backgroundViewPatternInsets = (UIEdgeInsets){ 8, 0, 0, 0 };
	
	UIView *backgroundView = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 320, 320 }];
	backgroundView.backgroundColor = [UIColor clearColor];
  
  [backgroundView addSubview:((^ {
  
    UIView *returnedView = [[UIView alloc] initWithFrame:CGRectInset(backgroundView.bounds, 1, 0)];
    returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    returnedView.layer.contents = (id)[UIImage imageNamed:@"WASquarePanelBackdrop"].CGImage;
    returnedView.layer.contentsScale = [UIScreen mainScreen].scale;
    returnedView.layer.contentsCenter = (CGRect){ 12.0/32.0f, 12.0/32.0f, 8.0/32.0f, 8.0/32.0f };
		
		returnedView.frame = UIEdgeInsetsInsetRect(returnedView.frame, backgroundViewPatternInsets);
    
    UIView *paperView = [[UIView alloc] initWithFrame:CGRectInset(returnedView.bounds, 4, 4)];
    paperView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    paperView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPostBackground"]];
    [returnedView addSubview:paperView];
    
    return returnedView;
  
  })())];
	
	return backgroundView;

}

UIView * WAStandardPostCellSelectedBackgroundView (void) {

	static UIEdgeInsets const backgroundViewPatternInsets = (UIEdgeInsets){ 8, 0, 0, 0 };
	
	UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 320, 320 }];
	selectedBackgroundView.backgroundColor = [UIColor clearColor];
  
  [selectedBackgroundView addSubview:((^ {
  
    UIView *returnedView = [[UIView alloc] initWithFrame:CGRectInset(selectedBackgroundView.bounds, 4, 4)];
    returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    returnedView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    
		returnedView.frame = UIEdgeInsetsInsetRect(returnedView.frame, backgroundViewPatternInsets);
		
    return returnedView;
    
  })())];

	return selectedBackgroundView;

}

UIView * WAStandardArticleStackCellBackgroundView (void) {

	UIView *backgroundView = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 320, 320 }];
	backgroundView.backgroundColor = [UIColor clearColor];
  
  [backgroundView addSubview:((^ {
  
    UIView *returnedView = [[UIView alloc] initWithFrame:backgroundView.bounds];
		returnedView.frame = UIEdgeInsetsInsetRect(returnedView.frame, (UIEdgeInsets){ -32, -32, 0, -32 });
    returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    returnedView.layer.contents = (id)[UIImage imageNamed:@"WAPlaintextArticleStackCellBackdrop"].CGImage;
    returnedView.layer.contentsScale = [UIScreen mainScreen].scale;
    returnedView.layer.contentsCenter = (CGRect){ 128.0/384.0, 48.0/128.0, 128.0/384.0, 32.0/128.0 };
		
    return returnedView;
  
  })())];
	
	return backgroundView;	

}

UIView * WAStandardArticleStackCellTopBackgroundView (void) {

	UIView *backgroundView = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 320, 320 }];
	
  [backgroundView addSubview:((^ {
  
		UIImage *image = [UIImage imageNamed:@"WAPlaintextArticleStackCellBackdrop"];
		UIView *returnedView = [[UIView alloc] initWithFrame:backgroundView.bounds];

		returnedView.frame = UIEdgeInsetsInsetRect(returnedView.frame, (UIEdgeInsets){ 0, -32, 0, -32 });
		returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		returnedView.layer.contents = (id)image.CGImage;
		returnedView.layer.contentsScale = image.scale;
		returnedView.layer.contentsRect = (CGRect){ 0.0/384.0, 32.0/128.0, 384.0/384.0, 16.0/128.0 };
		returnedView.layer.contentsCenter = (CGRect){ 128.0/384.0, 40.0/48.0, 128.0/384.0, 8.0/48.0 };

		return returnedView;
  
  })())];
	
	[backgroundView addSubview:((^ {
  
    UIView *returnedView = [[UIView alloc] initWithFrame:backgroundView.bounds];
		returnedView.frame = returnedView.frame;
    returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		returnedView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternSoftWallpaper"]];
		returnedView.alpha = 0.35f;
		
    return returnedView;
  
  })())];
	
	return backgroundView;

}

UIView * WAStandardArticleStackCellCenterBackgroundView (void) {

	UIView *backgroundView = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 320, 320 }];
	backgroundView.backgroundColor = [UIColor clearColor];
  
  [backgroundView addSubview:((^ {
  
    UIView *returnedView = [[UIView alloc] initWithFrame:backgroundView.bounds];
		returnedView.frame = UIEdgeInsetsInsetRect(returnedView.frame, (UIEdgeInsets){ 0, -32, 0, -32 });
    returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    returnedView.layer.contents = (id)[UIImage imageNamed:@"WAPlaintextArticleStackCellBackdrop"].CGImage;
    returnedView.layer.contentsScale = [UIScreen mainScreen].scale;
		returnedView.layer.contentsRect = (CGRect){ 0.0/384.0, 48.0/128.0, 384.0/384.0, 32.0/128.0 };
		returnedView.layer.contentsCenter = (CGRect){ 128.0/384.0, 0.0/32.0, 128.0/384.0, 32.0/32.0 };
		
    return returnedView;
  
  })())];
	
	[backgroundView addSubview:((^ {
  
    UIView *returnedView = [[UIView alloc] initWithFrame:backgroundView.bounds];
		returnedView.frame = returnedView.frame;
    returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		returnedView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternSoftWallpaper"]];
		returnedView.alpha = 0.35f;
		
    return returnedView;
  
  })())];

	return backgroundView;	

}

UIView * WAStandardArticleStackCellBottomBackgroundView (void) {

	UIView *backgroundView = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 320, 320 }];
	backgroundView.backgroundColor = [UIColor clearColor];
  
  [backgroundView addSubview:((^ {
  
    UIView *returnedView = [[UIView alloc] initWithFrame:backgroundView.bounds];
		returnedView.frame = UIEdgeInsetsInsetRect(returnedView.frame, (UIEdgeInsets){ 0, -32, -32, -32 });
    returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    returnedView.layer.contents = (id)[UIImage imageNamed:@"WAPlaintextArticleStackCellBackdrop"].CGImage;
    returnedView.layer.contentsScale = [UIScreen mainScreen].scale;
		returnedView.layer.contentsRect = (CGRect){ 0.0/384.0, 80.0/128.0, 384.0/384.0, 48.0/128.0 };
		returnedView.layer.contentsCenter = (CGRect){ 128.0/384.0, 0.0/48.0, 128.0/384.0, 8.0/48.0 };
		
    return returnedView;
  
  })())];
	
	[backgroundView addSubview:((^ {
  
    UIView *returnedView = [[UIView alloc] initWithFrame:backgroundView.bounds];
		returnedView.frame = returnedView.frame;
    returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		returnedView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternSoftWallpaper"]];
		returnedView.alpha = 0.35f;
		
    return returnedView;
  
  })())];
	
	return backgroundView;

}

CATransition* WADefaultImageTransition (void) {
	static CATransition *transition;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		transition = [CATransition animation];
		transition.type = kCATransitionFade;
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		transition.duration = 0.3;
		transition.removedOnCompletion = YES;
		transition.endProgress = 0.3;
	});
	
	return transition;
}
