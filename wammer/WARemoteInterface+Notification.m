//
//  WARemoteInterface+Notification.m
//  wammer
//
//  Created by Shen Steven on 8/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+Notification.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"


@implementation WARemoteInterface (Notification)


- (void) subscribeNotification
{
	WAWebSocketCommandHandler notifyHandler = ^ (id resp) {
		
		NSDictionary *result = (NSDictionary *) resp;
		
		NSString *message = [result objectForKey:@"message"];
		if (message) {
			// TODO: handle message
		}
		
		NSNumber *updated = [result objectForKey:@"updated"];
		if (updated) {
			if ([updated isEqualToNumber:[NSNumber numberWithBool:YES]]) {
				
//				[[WADataStore defaultStore] updateArticlesOnSuccess:nil onFailure:nil];
//				
//				[[WADataStore defaultStore] updateCurrentUserOnSuccess:nil onFailure:nil];
				
			}
		}
	};
	
	[[[self class] sharedWebSocket].commandHandlerMap setObject:notifyHandler forKey:@"notify"];
	
	NSDictionary *arguments = [[NSDictionary alloc]
														 initWithObjectsAndKeys: @"value", @"key", nil];
	
	NSString *rawData = composeWSJSONCommand(@"subscribe", arguments);
	if (rawData) {
		[[[self class] sharedWebSocket] send:rawData];
	}
}



@end
