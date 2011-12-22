//
//  WARemoteInterface+Storages.m
//  wammer
//
//  Created by Evadne Wu on 12/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Storages.h"

NSString * const kWARemoteInterfaceDropboxStorage = @"dropbox";


@implementation WARemoteInterface (Storages)

- (void) retrieveAuthorizationURLForStorage:(NSString *)aStorage onSuccess:(void(^)(NSURL *anURL))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"storages/authorize" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
		
		aStorage, @"type",
				
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[NSURL URLWithString:[inResponseOrNil valueForKeyPath:@"storages.authorization_url"]]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveAccessTokenForStorage:(NSString *)aStorage usingStationAccount:(NSString *)stationAccountOrNil onSuccess:(void(^)(NSString *token))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"storages/link" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
		
		aStorage, @"type",
		stationAccountOrNil, @"account",
				
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"session_token"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveStatusForStorage:(NSString *)aStorage onSuccess:(void(^)(WARemoteStorageStatus status, NSDate *timestamp))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"storages/check" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
		
		aStorage, @"type",
				
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[[inResponseOrNil valueForKeyPath:[NSString stringWithFormat:@"storage.%@.status", aStorage]] unsignedIntegerValue],
			[NSDate dateWithTimeIntervalSince1970:[[inResponseOrNil valueForKeyPath:[NSString stringWithFormat:@"storage.%@.update_time", aStorage]] doubleValue]]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) unlinkStorage:(NSString *)aStorage onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"storages/unlink" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
		
		aStorage, @"type",
				
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
	

}

@end
