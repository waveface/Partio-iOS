//
//  WADefines+iOS.m
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WADefines+iOS.h"

#import "IRBorder.h"
#import "IRShadow.h"
#import "IRBarButtonItem.h"

#import "UIImage+IRAdditions.h"
#import "WAAppDelegate.h"

#import "WAAppDelegate_iOS.h"

#import "IRWebAPIHelpers.h"
#import "UIKit+IRAdditions.h"


IRBorder *kWADefaultBarButtonBorder = nil;
IRShadow *kWADefaultBarButtonInnerShadow = nil;
IRShadow *kWADefaultBarButtonShadow = nil;

UIFont *kWADefaultBarButtonTitleFont = nil;
UIColor *kWADefaultBarButtonTitleColor = nil;
IRShadow *kWADefaultBarButtonTitleShadow = nil;

UIColor *kWADefaultBarButtonGradientFromColor = nil;
UIColor *kWADefaultBarButtonGradientToColor = nil;
NSArray *kWADefaultBarButtonGradientColors = nil;
UIColor *kWADefaultBarButtonBackgroundColor = nil;

UIColor *kWADefaultBarButtonHighlightedGradientFromColor = nil;
UIColor *kWADefaultBarButtonHighlightedGradientToColor = nil;
NSArray *kWADefaultBarButtonHighlightedGradientColors = nil;
UIColor *kWADefaultBarButtonHighlightedBackgroundColor = nil;


WAAppDelegate * AppDelegate (void) {

	return (WAAppDelegate_iOS *)[UIApplication sharedApplication].delegate;

}




BOOL WAIsXCallbackURL (NSURL *anURL, NSString **outCommand, NSDictionary **outParams) {

	if (![[anURL host] isEqualToString:@"x-callback-url"])
		return NO;
	
	if (outCommand) {
		*outCommand = [[anURL path] stringByReplacingOccurrencesOfString:@"/" withString:@"" options:0 range:(NSRange){ 0, 1 }];
	}

	if (outParams)
		*outParams = IRQueryParametersFromString([anURL query]);
	
	return YES;

}


