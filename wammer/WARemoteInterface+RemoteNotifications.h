//
//  WARemoteInterface+RemoteNotifications.h
//  wammer
//
//  Created by Shen Steven on 9/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (RemoteNotifications)


- (void) subscribeRemoteNotificationForDevtoken: (NSString*)aDevToken onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

- (void) unsubscribeRemoteNotificationForDevToken: (NSString*)aDevToken;

@end
