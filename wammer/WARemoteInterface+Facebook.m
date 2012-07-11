//
//  WARemoteInterface+Facebook.m
//  IRObjectQueue
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Iridia Productions. All rights reserved.
//

#import "WARemoteInterface+Facebook.h"

@implementation WARemoteInterface (Facebook)

- (void)signupUserWithFacebookToken:(NSString *)accessToken withOptions:(NSDictionary *)options onSuccess:(void (^)(NSDictionary *userRep, NSString *token))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSString *preferredLanguage = @"en";
	
	NSArray *preferredLanguages = [NSLocale preferredLanguages];
	if ([preferredLanguages count] > 0 && [[preferredLanguages objectAtIndex:0] isEqualToString:@"zh-Hant"]) {
		preferredLanguage = @"zh_tw";
	}
  
  NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"facebook", @"sns",
                           accessToken, @"auth_token",
                           @"yes", @"sns_connect",
                           @"yes", @"subscribed",
                           preferredLanguage, @"lang",
                           nil];
  [self.engine fireAPIRequestNamed:@"auth/signup"
										 withArguments:nil
													 options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(payload, nil)
												 validator:WARemoteInterfaceGenericNoErrorValidator()
										successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
											
											NSDictionary *userEntity = [[self class] userEntityFromRepresentation:inResponseOrNil];
											NSString *incomingToken = (NSString *)[inResponseOrNil objectForKey:@"session_token"];
											
											if (successBlock) {
												successBlock(userEntity, incomingToken);
											}
											
										}
										failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
	
}

@end
