//
//  WARemoteInterface+Storages.h
//  wammer
//
//  Created by Evadne Wu on 12/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

extern NSString * const kWARemoteInterfaceDropboxStorage;

#ifndef __WARemoteInterface_Storages__
#define __WARemoteInterface_Storages__

enum {

	WARemoteStorageUnknownStatus = -1024,

	WARemoteStorageNeverLinked = -1,
	WARemoteStorageLinked = 0,
	WARemoteStorageAuthorizationPending = 1,
	WARemoteStorageTemporarilyDisabled = 2,
	WARemoteStorageLinkedWithOtherAccount = 3

}; typedef NSInteger WARemoteStorageStatus;

#endif


@interface WARemoteInterface (Storages)

- (void) retrieveAuthorizationURLForStorage:(NSString *)aStorage onSuccess:(void(^)(NSURL *anURL))successBlock onFailure:(void(^)(NSError *error))failureBlock;

- (void) retrieveAccessTokenForStorage:(NSString *)aStorage usingStationAccount:(NSString *)stationAccountOrNil onSuccess:(void(^)(NSString *token))successBlock onFailure:(void(^)(NSError *error))failureBlock;

- (void) retrieveStatusForStorage:(NSString *)aStorage onSuccess:(void(^)(WARemoteStorageStatus status, NSDate *timestamp))successBlock onFailure:(void(^)(NSError *error))failureBlock;

- (void) unlinkStorage:(NSString *)aStorage onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
