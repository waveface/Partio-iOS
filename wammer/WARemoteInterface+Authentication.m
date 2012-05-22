//
//  WARemoteInterface+Authentication.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WARemoteInterface+Authentication.h"
#import "IRWebAPIEngine+FormURLEncoding.h"

@implementation WARemoteInterface (Authentication)

- (IRWebAPIRequestContextTransformer) defaultV2AuthenticationSignatureBlock {

	__weak WARemoteInterface *nrSelf = self;
	
	return ^ (NSDictionary *inOriginalContext) {
			
		NSMutableDictionary *mutatedContext = [inOriginalContext mutableCopy];
		
		BOOL shouldSign = YES;
		
		if ([[mutatedContext objectForKey:kIRWebAPIEngineIncomingMethodName] isEqualToString:@"auth/login"])
			shouldSign = NO;
		
		void (^sign)(NSMutableDictionary *) = ^ (NSMutableDictionary *fields) {
		
			if (nrSelf.apiKey) {
				[fields setObject:nrSelf.apiKey forKey:@"apikey"];
				[fields setObject:nrSelf.apiKey forKey:@"api_key"];
			}
			
			if (shouldSign && nrSelf.userToken)
				[fields setObject:nrSelf.userToken forKey:@"session_token"];

		};
		
		NSMutableDictionary *formMultipartFields = [[inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey] mutableCopy];
		if (formMultipartFields) {
			
			sign(formMultipartFields);
			[mutatedContext setObject:formMultipartFields forKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
			
		}
		
		NSMutableDictionary *formURLEncodedFields = [[inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey] mutableCopy];
		if (formURLEncodedFields) {
		
			sign(formURLEncodedFields);
			[mutatedContext setObject:formURLEncodedFields forKey:kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey];
		
		}
		
		NSMutableDictionary *queryParams = [[inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters] mutableCopy];
		
		if (!queryParams)
			queryParams = [NSMutableDictionary dictionary];
		
		sign(queryParams);
		[mutatedContext setObject:queryParams forKey:kIRWebAPIEngineRequestHTTPQueryParameters];
			
		return (NSDictionary *)mutatedContext;
	
	};

}

- (IRWebAPIResponseContextTransformer) defaultV2AuthenticationListeningBlock {

  __weak WARemoteInterface *nrSelf = self;

  return ^ (NSDictionary *inParsedResponse, NSDictionary *inResponseContext) {
  
    NSHTTPURLResponse *urlResponse = [inResponseContext objectForKey:kIRWebAPIEngineResponseContextURLResponse];
		
		BOOL canIntercept = YES;
		
		if (![urlResponse isKindOfClass:[NSHTTPURLResponse class]])
			canIntercept = NO;
		
		if ([[inResponseContext objectForKey:kIRWebAPIEngineIncomingMethodName] isEqualToString:@"reachability"])
			canIntercept = NO;
    
		if ([[[inResponseContext objectForKey:kIRWebAPIEngineResponseContextOriginalRequestContext] objectForKey:kIRWebAPIEngineIncomingMethodName] isEqualToString:@"reachability"])
			canIntercept = NO;
		
		if (!canIntercept)
			return inParsedResponse;
		
		if ((urlResponse.statusCode == 401) && nrSelf.userToken) {
		
			//  Token is failing right now
			
			NSUInteger returnCode = [[inParsedResponse valueForKeyPath:@"api_ret_code"] intValue];
			NSString *returnMessage = [inParsedResponse valueForKeyPath:@"api_ret_message"];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:kWARemoteInterfaceDidObserveAuthenticationFailureNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
			
				[NSError errorWithDomain:@"com.waveface.wammer.remoteInterface" code:returnCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
					returnMessage, NSLocalizedDescriptionKey,
				nil]], @"error",
			
			nil]];
		
		}
		
    return inParsedResponse;
    
  };

}

- (void) retrieveTokenForUser:(NSString *)anIdentifier password:(NSString *)aPassword onSuccess:(void(^)(NSDictionary *userRep, NSString *token))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(anIdentifier);
	NSParameterAssert(aPassword);
  
	[self.engine fireAPIRequestNamed:@"auth/login" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"email",
		aPassword, @"password",
    WADeviceName(), @"device_name",
    WADeviceIdentifier(), @"device_id",

	nil], nil) validator:^BOOL(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		if (![[inResponseOrNil objectForKey:@"session_token"] isKindOfClass:[NSString class]])
			return NO;
		
		if (![[inResponseOrNil objectForKey:@"user"] isKindOfClass:[NSDictionary class]])
			return NO;
			
		return YES;
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSDictionary *userEntity = [[self class] userEntityFromRepresentation:inResponseOrNil];
		NSString *incomingToken = (NSString *)[inResponseOrNil objectForKey:@"session_token"];
		
		if (successBlock) {
			successBlock(userEntity, incomingToken);
		}
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) discardToken:(NSString *)aToken onSuccess:(void (^)(void))successBlock onFailure:(void (^)(NSError *))failureBlock {

	[self.engine fireAPIRequestNamed:@"auth/logout" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
