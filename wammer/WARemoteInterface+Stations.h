//
//  WARemoteInterface+Stations.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Stations)

//	GET users/findMyStation
- (void) retrieveAssociatedStationsOfCurrentUserOnSuccess:(void(^)(NSArray *stationReps))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST stations/signup
- (void) registerStation:(NSString *)anIdentifier withURL:(NSURL *)anURL onSuccess:(void(^)(NSDictionary *stationRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST stations/logOn
- (void) activateStation:(NSString *)anIdentifier withURL:(NSURL *)anURL onSuccess:(void(^)(NSDictionary *stationRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST stations/logOff
- (void) deactivateStation:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *stationRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
