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
#import "IRWebAPIEngine+FormMultipart.h"

@implementation WARemoteInterface (Authentication)

- (IRWebAPIRequestContextTransformer) defaultV2AuthenticationSignatureBlock {

	__weak WARemoteInterface *wSelf = self;
	
	return ^ (IRWebAPIRequestContext *context) {
		
		BOOL shouldSign = YES;
		
		if ([context.engineMethod isEqualToString:@"auth/login"])
			shouldSign = NO;
		
		void (^sign)(NSMutableDictionary *) = ^ (NSMutableDictionary *fields) {
		
			if (wSelf.apiKey) {
				[fields setObject:wSelf.apiKey forKey:@"apikey"];
				[fields setObject:wSelf.apiKey forKey:@"api_key"];
			}
			
			if (shouldSign && wSelf.userToken)
				[fields setObject:wSelf.userToken forKey:@"session_token"];

		};
		
		NSMutableDictionary *formMultipartFields = [context.formMultipartFields mutableCopy];
		if ([[formMultipartFields allKeys] count]) {
			
			sign(formMultipartFields);
			
			[formMultipartFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				[context setValue:obj forFormMultipartField:key];
			}];
			
		}
		
		NSMutableDictionary *formURLEncodedFields = [context.formURLEncodingFields mutableCopy];
		if ([[formURLEncodedFields allKeys] count]) {
		
			sign(formURLEncodedFields);
			
			[formURLEncodedFields enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				[context setValue:obj forFormURLEncodingField:key];
			}];
			
		}
		
		NSMutableDictionary *queryParams = [context.queryParams mutableCopy];
		if (!queryParams)
			queryParams = [NSMutableDictionary dictionary];
			
		sign(queryParams);
		[queryParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[context setValue:obj forQueryParam:key];
		}];
		
		return context;
	
	};

}

- (IRWebAPIResponseContextTransformer) defaultV2AuthenticationListeningBlock {

  __weak WARemoteInterface *nrSelf = self;

  return ^ (NSDictionary *inParsedResponse, IRWebAPIRequestContext *inResponseContext) {
  
    NSHTTPURLResponse *urlResponse = inResponseContext.urlResponse;
		
		BOOL canIntercept = YES;
		
		if (![urlResponse isKindOfClass:[NSHTTPURLResponse class]])
			canIntercept = NO;
		
		if ([inResponseContext.engineMethod isEqualToString:@"reachability"])
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

	nil], nil) validator:^BOOL(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
	
		if (![[inResponseOrNil objectForKey:@"session_token"] isKindOfClass:[NSString class]])
			return NO;
		
		if (![[inResponseOrNil objectForKey:@"user"] isKindOfClass:[NSDictionary class]])
			return NO;
			
		return YES;
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
	
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
	
	nil] validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
