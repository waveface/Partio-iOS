//
//  WARemoteInterface+SocialNetworks.h
//  wammer
//
//  Created by Evadne Wu on 7/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (SocialNetworks)

- (void) connectSocialNetwork:(NSString *)network withOptions:(NSDictionary *)values onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *))failureBlock;

- (void) disconnectSocialNetwork:(NSString *)network purgeData:(BOOL)purge onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *))failureBlock;

- (void) retrieveConnectedSocialNetworksOnSuccess:(void(^)(NSArray *snsReps))successBlock onFailure:(void(^)(NSError *))failureBlock;

@end
