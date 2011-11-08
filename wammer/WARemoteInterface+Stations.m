//
//  WARemoteInterface+Stations.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Stations.h"

@implementation WARemoteInterface (Stations)

- (void) retrieveAssociatedStationsOfCurrentUserOnSuccess:(void(^)(NSArray *stationReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"users/findMyStation" withArguments:nil options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (successBlock)
			successBlock([inResponseOrNil valueForKeyPath:@"stations"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) registerStation:(NSString *)anIdentifier withURL:(NSURL *)anURL onSuccess:(void(^)(NSDictionary *stationRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"stations/signup" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"station_id",
		[anURL absoluteURL], @"location",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil valueForKeyPath:@"station"]);
	
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) activateStation:(NSString *)anIdentifier withURL:(NSURL *)anURL onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"stations/logOn" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"station_id",
		[anURL absoluteURL], @"location",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock();
	
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) deactivateStation:(NSString *)anIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"stations/logOff" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"station_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock();
	
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
