//
//  WARemoteInterface+Users.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WARemoteInterface+Users.h"
#import "IRWebAPIEngine+FormURLEncoding.h"

@implementation WARemoteInterface (Users)

- (void) registerUser:(NSString *)anIdentifier password:(NSString *)aPassword nickname:(NSString *)aNickname onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(anIdentifier);
	NSParameterAssert(aNickname);
	
	[self.engine fireAPIRequestNamed:@"auth/signup" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
				
		anIdentifier, @"email",
		aPassword, @"password",
		aNickname, @"nickname",
				
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil valueForKeyPath:@"user"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveUser:(NSString *)anIdentifier onSuccess:(void (^)(NSDictionary *, NSArray *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(anIdentifier);
	
	[self.engine fireAPIRequestNamed:@"users/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
		
		anIdentifier, @"user_id",
				
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"user"],
			[inResponseOrNil valueForKeyPath:@"groups"]
		);
		
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setValue:[inResponseOrNil valueForKeyPath:@"storages"] forKeyPath:kWAUserStorageInfo];
		[userDefaults synchronize];
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) updateUser:(NSString *)anIdentifier withNickname:(NSString *)aNewNickname onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	[self.engine fireAPIRequestNamed:@"users/update" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
				
		anIdentifier, @"user_id",
		aNewNickname, @"nickname",
				
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"user"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) resetPasswordOfCurrentUserFrom:(NSString *)anOldPassword To:(NSString *)aNewPassword onSuccess:(void (^)(void))successBlock onFailure:(void (^)(NSError *))failureBlock {

		[self.engine fireAPIRequestNamed:@"users/passwd" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
				
		anOldPassword, @"old_passwd",
		aNewPassword, @"new_passwd",
				
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
