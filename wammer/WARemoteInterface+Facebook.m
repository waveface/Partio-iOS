//
//  WARemoteInterface+Facebook.m
//  IRObjectQueue
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Iridia Productions. All rights reserved.
//

#import "WARemoteInterface+Facebook.h"

@implementation WARemoteInterface (Facebook)

- (void)signupUserWithFacebookToken:(NSString *)accessToken withOptions:(NSDictionary *)options onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"facebook", @"sns",
                           accessToken, @"auth_token",
                           @"yes", @"sns_connect",
                           @"yes", @"subscribed",
                           @"ZH_TW", @"lang",
                           nil];
  [self.engine fireAPIRequestNamed:@"auth/signup" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(payload, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
    
		if (successBlock)
			successBlock([inResponseOrNil valueForKeyPath:@"user"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
