//
//  WARemoteInterface+SocialNetworks.m
//  wammer
//
//  Created by Evadne Wu on 7/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+SocialNetworks.h"

@implementation WARemoteInterface (SocialNetworks)

- (void) connectSocialNetwork:(NSString *)network
										withToken:(NSString *)token
										onSuccess:(void(^)(void))successBlock
										onFailure:(void(^)(NSError *))failureBlock {

	NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:
		network, @"sns",
		token, @"auth_token",
	nil];
	
	NSDictionary *options = WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(payload, nil);
	
	IRWebAPIResponseValidator validator = WARemoteInterfaceGenericNoErrorValidator();

	[self.engine
	 fireAPIRequestNamed:@"users/SNSConnect"
	 withArguments:nil
	 options:options
	 validator:validator
	 successHandler: ^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		 if (successBlock) {
			 successBlock();
		 }
	 }
	 failureHandler: WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) disconnectSocialNetwork:(NSString *)network purgeData:(BOOL)purge onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *))failureBlock {

	NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:
		network, @"sns",
		(purge ? @"yes" : @"no"), @"purge_all",
	nil];
	
	NSDictionary *options = WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(payload, nil);
	
	IRWebAPIResponseValidator validator = WARemoteInterfaceGenericNoErrorValidator();

	[self.engine fireAPIRequestNamed:@"users/SNSDisconnect" withArguments:nil options:options validator:validator successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
											
		if (successBlock) {
			successBlock();
		}

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveConnectedSocialNetworksOnSuccess:(void(^)(NSArray *snsReps))successBlock onFailure:(void(^)(NSError *))failureBlock {

	IRWebAPIResponseValidator validator = WARemoteInterfaceGenericNoErrorValidator();
	
	[self.engine fireAPIRequestNamed:@"users/SNSStatus" withArguments:nil options:nil validator:validator successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
											
		if (successBlock) {
			successBlock([inResponseOrNil valueForKeyPath:@"sns"]);
		}

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
