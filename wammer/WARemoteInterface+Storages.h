//
//  WARemoteInterface+Storages.h
//  wammer
//
//  Created by Evadne Wu on 12/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"


extern NSString * const kWARemoteInterfaceDropboxStorage;


@interface WARemoteInterface (Storages)

- (void) retrieveAuthorizationURLForStorage:(NSString *)aStorage onSuccess:(void(^)(NSURL *anURL))successBlock onFailure:(void(^)(NSError *error))failureBlock;

- (void) retrieveAccessTokenForStorage:(NSString *)aStorage usingStationAccount:(NSString *)stationAccountOrNil onSuccess:(void(^)(NSString *token))successBlock onFailure:(void(^)(NSError *error))failureBlock;

- (void) retrieveStatusForStorage:(NSString *)aStorage usingStationAccount:(NSString *)stationAccountOrNil onSuccess:(void(^)(int status, NSDate *timestamp))successBlock onFailure:(void(^)(NSError *error))failureBlock;

- (void) unlinkStorage:(NSString *)aStorage onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
