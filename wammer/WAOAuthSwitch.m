//
//  WAOAuthSwitch.m
//  wammer
//
//  Created by kchiu on 12/11/29.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAOAuthSwitch.h"
#import "IRWebAPIHelpers.h"

@implementation WAOAuthSwitch

- (BOOL)isSuccessURL:(NSURL *)resultURL {

	NSParameterAssert([NSThread isMainThread]);

	if (!resultURL) {
		return NO;
	}

	NSDictionary *response = IRQueryParametersFromString([resultURL absoluteString]);
	NSInteger code = [response[@"api_ret_code"] integerValue];
	NSString *message = response[@"api_ret_message"];
	
	if (code != 0) {
		NSLog(@"OAuth failed, code: %d, message: %@", code, message);
		return NO;
	}

	return YES;

}

@end
