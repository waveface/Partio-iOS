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
#import "WAStation.h"
#import "WADataStore.h"

static NSString * const kConnectionForWebSocket = @"kConnectionForWebSocket";

@implementation WARemoteInterface (WebSocket)
@dynamic connectionForWebSocket;


- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {
  
  self.connectionForWebSocket = [[WAWebSocket alloc] initWithUrl:anURL apikey:self.apiKey usertoken:self.userToken userIdentifier:self.userIdentifier];
  
  [self.connectionForWebSocket openConnectionOnSucces:successBlock onFailure:failureBlock];
  
}

- (void) connectAvaliableWSStation:(NSArray *)allStations onSuccess:(void(^)(WAStation *station))successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {
  
  if ([allStations count] == 0) {
    failureBlock(nil);
    return;
  }
  
  WAStation *station = allStations[0];
  
  if (self.connectionForWebSocket == nil || self.connectionForWebSocket.webSocketState == WAWebSocketClosed) {
    
    // Station will clean its ws_location field when it is suspended,
    // so we don't have to connect to the suspended station.
    if (!station.wsURL) {
      [self connectAvaliableWSStation:[allStations subarrayWithRange:NSMakeRange(1, [allStations count]-1)]
		         onSuccess:successBlock
		         onFailure:failureBlock];
      return;
    }

    __weak WARemoteInterface *wSelf = self;
    [[WARemoteInterface sharedInterface]
     openWebSocketConnectionForUrl:[NSURL URLWithString:station.wsURL]
     onSucces:^{
       successBlock(station);
     }
     onFailure:^(NSError *error) {
       // TODO: We have to know the error is caused by server unavailable or disconnection,
       // so that we can decide to try next station or restart the station discovery routine.
       [wSelf connectAvaliableWSStation:[allStations subarrayWithRange:NSMakeRange(1, [allStations count]-1)]
			 onSuccess:successBlock
			onFailure:failureBlock];
     }];
    
  } else {

    successBlock(nil);

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
