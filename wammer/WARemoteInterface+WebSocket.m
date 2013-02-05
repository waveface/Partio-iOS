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

+ (WAWebSocket *)sharedWebSocket {
  
  static WAWebSocket *socket = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	socket = [[WAWebSocket alloc] initWithApikey:ri.apiKey usertoken:ri.userToken userIdentifier:ri.userIdentifier];
  });
  return socket;
  
}

- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {

  WAWebSocket *socket = [[self class] sharedWebSocket];
  
  [socket openConnectionToUrl:anURL onSucces:successBlock onFailure:failureBlock];
  
}

- (void) connectAvaliableWSStation:(NSArray *)allStations onSuccess:(void(^)(WAStation *station))successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {
  
  if ([allStations count] == 0) {
    failureBlock(nil);
    return;
  }
  
  WAStation *station = allStations[0];
  
  WAWebSocket *currentSocket = [[self class] sharedWebSocket];
  if (currentSocket.webSocketState == WAWebSocketClosed) {
    
    // Station will clean its ws_location field when it is suspended,
    // so we don't have to connect to the suspended station.
    if ([station.wsURL length] == 0) {
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

  WAWebSocket *socket = [[self class] sharedWebSocket];
  [socket closeConnectionWithCode:WAWebSocketNormal andReason:@""];
  
}

- (BOOL) webSocketConnected {
  WAWebSocket *socket = [[self class] sharedWebSocket];
  return socket.webSocketConnected;
}

@end
