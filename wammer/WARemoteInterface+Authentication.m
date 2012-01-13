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

	__block __typeof__(self) nrSelf = self;
	
	return [[ ^ (NSDictionary *inOriginalContext) {
			
		NSMutableDictionary *mutatedContext = [[inOriginalContext mutableCopy] autorelease];
		NSMutableDictionary *originalFormMultipartFields = [inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
		NSMutableDictionary *originalFormURLEncodedFields = [inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey];
		
		BOOL shouldSign = YES;
		
		if ([[mutatedContext objectForKey:kIRWebAPIEngineIncomingMethodName] isEqualToString:@"auth/login"])
			shouldSign = NO;
		
		if (originalFormMultipartFields) {
		
			NSMutableDictionary *mutatedFormMultipartFields = [[originalFormMultipartFields mutableCopy] autorelease];
			[mutatedContext setObject:mutatedFormMultipartFields forKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
			
			if (nrSelf.apiKey)
				[mutatedFormMultipartFields setObject:nrSelf.apiKey forKey:@"apikey"];
			
			if (shouldSign && nrSelf.userToken)
				[mutatedFormMultipartFields setObject:nrSelf.userToken forKey:@"session_token"];
			
		} else if (originalFormURLEncodedFields) {
		
			NSMutableDictionary *mutatedFormURLEncodedFields = [[originalFormURLEncodedFields mutableCopy] autorelease];
			[mutatedContext setObject:mutatedFormURLEncodedFields forKey:kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey];
			
			if (nrSelf.apiKey)
				[mutatedFormURLEncodedFields setObject:nrSelf.apiKey forKey:@"apikey"];
			
			if (shouldSign && nrSelf.userToken)
				[mutatedFormURLEncodedFields setObject:nrSelf.userToken forKey:@"session_token"];
		
		} else {
		
			NSDictionary *originalQueryParams = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
			NSMutableDictionary *mutatedQueryParams = [[originalQueryParams mutableCopy] autorelease];
			
			if (!mutatedQueryParams)
					mutatedQueryParams = [NSMutableDictionary dictionary];
			
			[mutatedContext setObject:mutatedQueryParams forKey:kIRWebAPIEngineRequestHTTPQueryParameters];
			
			if (nrSelf.apiKey)
				[mutatedQueryParams setObject:nrSelf.apiKey forKey:@"apikey"];
			
			if (shouldSign && nrSelf.userToken)
				[mutatedQueryParams setObject:nrSelf.userToken forKey:@"session_token"];
		
		}
		
		return (NSDictionary *)mutatedContext;
	
	} copy] autorelease];

}

- (IRWebAPIResponseContextTransformer) defaultV2AuthenticationListeningBlock {

  __block __typeof__(self) nrSelf = self;

  return [[ ^ (NSDictionary *inParsedResponse, NSDictionary *inResponseContext) {
  
    NSHTTPURLResponse *urlResponse = [inResponseContext objectForKey:kIRWebAPIEngineResponseContextURLResponse];
		
		BOOL canIntercept = YES;
		
		if (![urlResponse isKindOfClass:[NSHTTPURLResponse class]])
			canIntercept = NO;
		
		if ([[inResponseContext objectForKey:kIRWebAPIEngineIncomingMethodName] isEqualToString:@"reachability"])
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
    
  } copy] autorelease];

}

- (void) retrieveTokenForUser:(NSString *)anIdentifier password:(NSString *)aPassword onSuccess:(void(^)(NSDictionary *userRep, NSString *token))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(anIdentifier);
	NSParameterAssert(aPassword);
  
  NSString *aDevice = [[UIDevice currentDevice] name];
  
	[self.engine fireAPIRequestNamed:@"auth/login" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"email",
		aPassword, @"password",
    aDevice, @"device_name",
    
    WADeviceIdentifier(), @"device_id",

	nil], nil) validator:^BOOL(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		if (![[inResponseOrNil objectForKey:@"session_token"] isKindOfClass:[NSString class]])
			return NO;
		
		if (![[inResponseOrNil objectForKey:@"user"] isKindOfClass:[NSDictionary class]])
			return NO;
			
		return YES;
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSString *incomingToken = (NSString *)[inResponseOrNil objectForKey:@"session_token"];
		NSMutableDictionary *userEntity = [[[inResponseOrNil valueForKeyPath:@"user"] mutableCopy] autorelease];
		
		if (!userEntity)
			userEntity = [NSMutableDictionary dictionary];
		
		if ([inResponseOrNil valueForKeyPath:@"groups"])
			[userEntity setObject:[inResponseOrNil valueForKeyPath:@"groups"] forKey:@"groups"];
			
		if ([inResponseOrNil valueForKeyPath:@"stations"])
			[userEntity setObject:[inResponseOrNil valueForKeyPath:@"stations"] forKey:@"stations"];
		
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
