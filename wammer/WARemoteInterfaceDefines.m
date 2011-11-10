//
//  WARemoteInterfaceDefines.m
//  wammer
//
//  Created by Evadne Wu on 11/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "IRWebAPIKit.h"
#import "WARemoteInterfaceDefines.h"
#import "IRWebAPIEngine+FormURLEncoding.h"

NSString *kWARemoteInterfaceDomain = @"com.waveface.wammer.remoteInterface";
NSString *kWARemoteInterfaceUnderlyingError = @"WARemoteInterfaceUnderlyingError";
NSString *kWARemoteInterfaceUnderlyingContext = @"WARemoteInterfaceUnderlyingContext";
NSString *kWARemoteInterfaceRemoteErrorCode = @"WARemoteInterfaceRemoteErrorCode";

void WARemoteInterfaceNotPorted (void) {

	[NSException raise:NSObjectNotAvailableException format:@"%s has not been modified to use v.2 API methods.  Returning immediately."];

}

NSUInteger WARemoteInterfaceEndpointReturnCode (NSDictionary *response) {

	return [[response valueForKeyPath:@"api_ret_code"] unsignedIntValue];

};

NSString * WARemoteInterfaceEndpointReturnMessage (NSDictionary *response) {

	return IRWebAPIKitStringValue([response valueForKeyPath:@"api_ret_message"]);

};

NSError * WARemoteInterfaceGenericError (NSDictionary *response, NSDictionary *context) {

	NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
	
	[errorUserInfo setObject:[NSNumber numberWithUnsignedInt:WARemoteInterfaceEndpointReturnCode(response)] forKey:kWARemoteInterfaceRemoteErrorCode];
	
	if ([context objectForKey:kIRWebAPIEngineUnderlyingError])
		[errorUserInfo setObject:[context objectForKey:kIRWebAPIEngineUnderlyingError] forKey:kWARemoteInterfaceUnderlyingError];
	
	if (context)
		[errorUserInfo setObject:context forKey:kWARemoteInterfaceUnderlyingContext];

	return [NSError errorWithDomain:kWARemoteInterfaceDomain code:0 userInfo:errorUserInfo];

}

IRWebAPICallback WARemoteInterfaceGenericFailureHandler (void(^aFailureBlock)(NSError *)) {

	if (!aFailureBlock)
		return (IRWebAPICallback)nil;
	
	return [[ ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		aFailureBlock(WARemoteInterfaceGenericError(inResponseOrNil, inResponseContext));
		
	} copy] autorelease];

};

IRWebAPIResposeValidator WARemoteInterfaceGenericNoErrorValidator () {

	return [[ ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		BOOL answer = [[inResponseOrNil valueForKey:@"api_ret_code"] isEqual:[NSNumber numberWithInt:WASuccess]];
		answer &= ([((NSHTTPURLResponse *)[inResponseContext objectForKey:kIRWebAPIEngineResponseContextURLResponseName]) statusCode] == 200);
		
		if (!answer) {
			NSLog(@"Error: %@", inResponseOrNil);		
		}
		
		return answer;
	
	} copy] autorelease];

};

NSDictionary *WARemoteInterfaceRFC3986EncodedDictionary (NSDictionary *encodedDictionary) {

	NSMutableDictionary *returnedDictionary = [NSMutableDictionary dictionaryWithCapacity:[encodedDictionary count]];
	
	[encodedDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[returnedDictionary setObject:IRWebAPIKitRFC3986EncodedStringMake(obj) forKey:key];
	}];
	
	return returnedDictionary;

}

NSDictionary *WARemoteInterfaceEnginePostFormEncodedOptionsDictionary (NSDictionary *parameters, NSDictionary *mergedOtherOptionsOrNil) {

	NSMutableDictionary *returnedDictionary = [NSMutableDictionary dictionary];
	parameters = WARemoteInterfaceRFC3986EncodedDictionary(parameters);
	
	if (parameters)
		[returnedDictionary setObject:parameters forKey:kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey];
	
	[returnedDictionary setObject:@"POST" forKey:kIRWebAPIEngineRequestHTTPMethod];
	
	if (mergedOtherOptionsOrNil)
		[returnedDictionary addEntriesFromDictionary:mergedOtherOptionsOrNil];
	
	return returnedDictionary;

}
