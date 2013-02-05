//
//  WAWebSocket.h
//  wammer
//
//  Created by Shen Steven on 9/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketRocket/SRWebSocket.h"

typedef enum WAWebSocketResponseCode : NSUInteger {
	WAWebSocketNormal = 1000,
	WAWebSocketGoingAwayError,
	WAWebSocketProtocolError,
	WAWebSocketFormationError,
	WAWevSocketReserved,
	WAWebSocketNoStatusError,
	WAWebSocketAbnormalError,
  WAWebSocketInconsistentDataError,
	WAWebSocketPolicyViolationError,
	WAWebSocketMessageTooLargeError,
	WAWebSocketHandshakeError,
	WAWebSocketUnexpectedServerError,
	WAWebSocketPermissionDeniedError = 3001
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

extern NSString * composeWSJSONCommand (NSString* command, NSDictionary* arguments);


@interface WAWebSocket : NSObject <SRWebSocketDelegate>

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, strong) NSString *userIdentifier;

@property (nonatomic, readonly) WAWebSocketState webSocketState;
@property (nonatomic, readonly) BOOL webSocketConnected;
@property (nonatomic, strong) NSMutableDictionary *commandHandlerMap;

@property (nonatomic, strong) SRWebSocket *connectionForWebSocket;

- (id) init;

/**
 * Init a WAWebSocket instance with specified parameters 
 * @param theApiKey Waveface Stream device APIKey
 * @param theUserToken Waveface Stream authentication session token
 * @param theUserIdentifier Waveface Stream user identity
 */
- (id) initWithApikey:(NSString*)theApiKey usertoken:(NSString*)theUserToken userIdentifier:(NSString*)theUserIdentifier;

/**
 * Open the websocket connection.
 * @param successBlock the completion block which will be executed while connection is setup.
 * @param failureBlock the completion block which will be executed if the connection is unable to be setup
 */
- (void) openConnectionToUrl:(NSURL*)anURL onSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock;

/**
 * Close the connection with specified code and reason
 */
- (void) closeConnectionWithCode:(NSInteger)code andReason:(NSString*)reason;

/**
 * Send the data
 */
- (void) send:(id)data;

@end
