//
//  WARemoteInterface+Facebook.m
//  IRObjectQueue
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Iridia Productions. All rights reserved.
//

#import "WARemoteInterface+Facebook.h"
#import "WADefines.h"

@implementation WARemoteInterface (Facebook)

- (void) signupUserWithFacebookToken:(NSString *)accessToken withOptions:(NSDictionary *)options onSuccess:(void (^)(NSString *token, NSDictionary *userRep, NSArray *groupReps))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSString *preferredLanguage = @"en";
	
	NSArray *preferredLanguages = [NSLocale preferredLanguages];
	if ([preferredLanguages count] > 0 && [[preferredLanguages objectAtIndex:0] isEqualToString:@"zh-Hant"]) {
		preferredLanguage = @"zh_tw";
	}
  
	NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:

		accessToken, @"auth_token",
		preferredLanguage, @"lang",
		@"facebook", @"sns",
		@"no", @"sns_connect",
		@"yes", @"subscribed",
		WADeviceName(), @"device_name",
		WADeviceIdentifier(), @"device_id",

	nil];
	
	[self.engine fireAPIRequestNamed:@"auth/signup" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(payload, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
											
		if (successBlock) {
			successBlock(
				[inResponseOrNil valueForKeyPath:@"session_token"],
				[[self class] userEntityFromRepresentation:inResponseOrNil],
				[inResponseOrNil valueForKeyPath:@"groups"]
			);
		}

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
	
}

@end
