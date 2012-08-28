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

- (NSString *) composeJSONStringForCommand:(NSString*)command withArguments:(NSDictionary *)arguments {
	NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:arguments, command, nil];
	if ([NSJSONSerialization isValidJSONObject:data]) {
		NSError *error = nil;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
		if (jsonData)
			return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	}
	return nil;
}

- (void) subscribeNotification
{
	WAWebSocketCommandHandler notifyHandler = ^ (id resp) {
		
		NSDictionary *result = (NSDictionary *) resp;
		
		NSNumber *connected = [result objectForKey:@"connected"];
		if (connected) {
			if ([connected isEqualToNumber:[NSNumber numberWithBool:YES]]) {
			} else {
				// FIXME: handle failure?
			}
		}
		
		NSString *message = [result objectForKey:@"message"];
		if (message) {
			// TODO: handle message
		}
		
		NSNumber *updated = [result objectForKey:@"updated"];
		if (updated) {
			if ([updated isEqualToNumber:[NSNumber numberWithBool:YES]]) {
				// TODO: handle update
				
				/*
				[[WADataStore defaultStore] updateArticlesOnSuccess:nil onFailure:nil];
				
				[[WADataStore defaultStore] updateCurrentUserOnSuccess:nil onFailure:nil];
*/
			}
		}
	};
	
	[self.commandHandlerMap setObject:notifyHandler forKey:@"notify"];
	
	NSDictionary *arguments = [[NSDictionary alloc]
														 initWithObjectsAndKeys: self.apiKey, @"apikey",
																										 self.userToken, @"session_token",
																										 self.userIdentifier, @"user_id", nil];
	
	NSString *rawData = [self composeJSONStringForCommand:@"subscribe" withArguments:arguments];
	if (rawData) {
		[self.connectionForWebSocket send:rawData];
	}
}



@end
