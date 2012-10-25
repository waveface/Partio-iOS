//
//  WARemoteInterface+WebSocket.m
//  wammer
//
//  Created by Shen Steven on 8/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+WebSocket.h"
#import "WARemoteInterfaceDefines.h"
#import "WARemoteInterface+Reachability.h"

static NSString * const kConnectionForWebSocket = @"kConnectionForWebSocket";

@implementation WARemoteInterface (WebSocket)
@dynamic connectionForWebSocket;


- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {
	
	self.connectionForWebSocket = [[WAWebSocket alloc] initWithUrl:anURL apikey:self.apiKey usertoken:self.userToken userIdentifier:self.userIdentifier];
	
	[self.connectionForWebSocket openConnectionOnSucces:successBlock onFailure:failureBlock];
	
}

- (void) connectAvaliableWSStation:(NSArray *)allStations onSucces:(void(^)(NSURL *wsURL, NSURL*stURL, NSString *computerName))successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {
	
	if ([allStations count] == 0) {
		failureBlock(nil);
		return;
	}
	
	NSURL *wsURL = allStations[0][@"ws_location"];
	NSURL *stURL = allStations[0][@"location"];
	NSString *computerName = allStations[0][@"computer_name"];

	if (self.connectionForWebSocket == nil || self.connectionForWebSocket.webSocketState == WAWebSocketClosed) {
		
		__weak WARemoteInterface *wSelf = self;
		[[WARemoteInterface sharedInterface]
		 openWebSocketConnectionForUrl: wsURL
		 onSucces:^{
			 successBlock(wsURL, stURL, computerName);
		 }
		 onFailure:^(NSError *error) {
			 [wSelf connectAvaliableWSStation:[allStations subarrayWithRange:NSMakeRange(1, [allStations count]-1)]
															 onSucces:successBlock
															onFailure:failureBlock];
		 }];
		
	}
		
}

- (void) closeWebSocketConnection {
	
	[self.connectionForWebSocket closeConnectionWithCode:WAWebSocketNormal andReason:@""];
	
}

- (BOOL) webSocketConnected {
	return self.connectionForWebSocket.webSocketConnected;
}


#pragma mark - setters and getters for properties
- (WAWebSocket *) connectionForWebSocket {

	return (WAWebSocket*)objc_getAssociatedObject(self, &kConnectionForWebSocket);

}

- (void) setConnectionForWebSocket:(WAWebSocket *)connectionForWebSocket {
	
	objc_setAssociatedObject(self, &kConnectionForWebSocket, connectionForWebSocket, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}


@end
