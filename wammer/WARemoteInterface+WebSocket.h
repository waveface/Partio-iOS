//
//  WARemoteInterface+WebSocket.h
//  wammer
//
//  Created by Shen Steven on 8/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"
#import "WAWebSocket.h"

/* This category is reserved to handle multiple websocket connections in the future
 */

@interface WARemoteInterface (WebSocket)

/// A websocket instance
@property (nonatomic, strong) WAWebSocket *connectionForWebSocket;

/// @return YES if websocket is connected, NO if not.
@property (nonatomic, readonly) BOOL webSocketConnected;

- (void) connectAvaliableWSStation:(NSArray *)allStations onSucces:(void(^)(NSURL *wsURL, NSURL*stURL))successBlock onFailure:(WAWebSocketConnectFailure)failureBlock;

/**
 * Open a new websocket connection to a specified URL.
 
 * @param anURL the url you would like to connect to.
 * @param onSuccess the completion block when websocket successfully connected
 * @param onFailure the failure block when websocket failed to connect with
 */
- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock;

/**
 * Close the connected websocket connection.
 */
- (void) closeWebSocketConnection;


@end
