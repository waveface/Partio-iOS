//
//  WARemoteInterface+WebSocket.h
//  wammer
//
//  Created by Shen Steven on 8/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"
#import "SocketRocket/SRWebSocket.h"

typedef enum WAWebSocketResponseCode : NSUInteger {
	WAWebSocketNormal = 1000,
	WAWebSocketStationGoingAway,
	WAWebSocketProtocolError,
	WAWebSocketFormationError,
	WAWebSocketNoStatus,
	WAWebSocketAbnormalError,
	WAWebSocketPolicyViolationError,
	WAWebSocketMessageTooLargeError,
	WAWebSocketHandshakeError,
	WAWebSocketUnexpectedServerError
} WAWebSocketResponseCode;

typedef void (^WAWebSocketCommandHandler) (id);
typedef void (^WAWebSocketConnectCallback) (void);
typedef void (^WAWebSocketConnectFailure) (NSError *);

@interface WARemoteInterface (WebSocket)
@property (nonatomic, strong) SRWebSocket *connectionForWebSocket;
@property (nonatomic, strong) NSMutableDictionary *commandHandlerMap;

- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock;

@end
