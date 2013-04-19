//
//  WARemoteInterface+RemoteNotifications.m
//  wammer
//
//  Created by Shen Steven on 9/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+RemoteNotifications.h"

@implementation WARemoteInterface (RemoteNotifications)

- (void) subscribeRemoteNotificationForDevtoken: (NSString*)aDevToken onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(aDevToken);
	
	[self.engine fireAPIRequestNamed:@"pio_notifications/send_apnstoken"
                       withArguments:[NSDictionary dictionaryWithObjectsAndKeys:aDevToken, @"apns_token", nil]
                             options:nil
                           validator:WARemoteInterfaceGenericNoErrorValidator()
                      successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
                        
                        if (!successBlock)
                          return;
		
                        successBlock();
                        
                      } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
  
  
}

- (void) unsubscribeRemoteNotificationForDevToken: (NSString*)aDevToken {

	[self.engine fireAPIRequestNamed:@"notifications/unsubscribe" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
																																							 @"iOS", @"ostype", nil]
													 options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:nil failureHandler:nil];
	
	
}


@end
