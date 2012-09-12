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

- (void) connectAvaliableWSStation:(NSArray *)allStations onSucces:(void(^)(NSURL *wsURL, NSURL*stURL))successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {
	
	BOOL stationAvailable = NO;
	NSURL *wsURL = nil;
	NSURL *stURL = nil;
	
	for (NSDictionary *entry in allStations) {
		wsURL = [(NSDictionary*)entry objectForKey:@"ws_location"];
		stURL = [(NSDictionary*)entry objectForKey:@"location"];
		
		WAReachabilityDetector *detector = [self reachabilityDetectorForHost:stURL];
		// no detector for this station exists, might be a new entry from findMyStation
		if (!detector) {
			stationAvailable = YES;
			break;
		}
		
		// a station is alive and supports ws
		if (detector && detector.state == WAReachabilityStateAvailable) {
			stationAvailable = YES;
			break;
		}
	}
	
	if (stationAvailable) {
		
			[[WARemoteInterface sharedInterface] openWebSocketConnectionForUrl: wsURL
																															onSucces:^{
																																successBlock(wsURL, stURL);
																															}
																														 onFailure:failureBlock];
	} else {
		failureBlock(nil);
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
