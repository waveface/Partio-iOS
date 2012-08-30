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
	WAWebSocketStationGoingAway = 1001,
	WAWebSocketProtocolError = 1002,
	WAWebSocketFormationError = 1003,
	WAWebSocketNoStatus = 1005,
	WAWebSocketAbnormalError = 1006,
  WAWebSocketInconsistentData = 1007,
	WAWebSocketPolicyViolationError = 1008,
	WAWebSocketMessageTooLargeError = 1009,
	WAWebSocketHandshakeError = 1010,
	WAWebSocketUnexpectedServerError = 1011
} WAWebSocketResponseCode;

typedef enum WAWebSocketState : NSUInteger {
	WAWebSocketConnecting = 0,
	WAWebSocketOpen,
	WAWebSocketClosing,
	WAWebSocketClosed
} WAWebSocketState;

typedef void (^WAWebSocketCommandHandler) (id);
typedef void (^WAWebSocketConnectCallback) (void);
typedef void (^WAWebSocketConnectFailure) (NSError *);

@interface WARemoteInterface (WebSocket)
@property (nonatomic, strong) SRWebSocket *connectionForWebSocket;
@property (nonatomic, strong) NSMutableDictionary *commandHandlerMap;
@property (nonatomic, readonly) NSUInteger webSocketState;
@property (nonatomic, readonly) BOOL webSocketConnected;

- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock;
- (void) closeWebSocketConnectionWithCode:(NSInteger)code andReason:(NSString*)reason;
- (NSString *) composeJSONStringForCommand:(NSString*)command withArguments:(NSDictionary *)arguments;

@end
