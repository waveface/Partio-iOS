//
//  WARemoteInterface+Authentication.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Authentication)

- (IRWebAPIRequestContextTransformer) defaultV2AuthenticationSignatureBlock;

//	POST auth/login
- (void) retrieveTokenForUser:(NSString *)anIdentifier password:(NSString *)aPassword onSuccess:(void(^)(NSDictionary *userRep, NSString *token))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST auth/logout
- (void) discardToken:(NSString *)aToken onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
