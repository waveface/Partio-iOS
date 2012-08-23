//
//  WARemoteInterface+WebSocket.h
//  wammer
//
//  Created by Shen Steven on 8/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"
#import "SocketRocket/SRWebSocket.h"
typedef void (^WAWebSocketHandler) (id);
typedef void (^WAWebSocketCallback) (void);
typedef void (^WAWebSocketFailure) (NSError *);

@interface WARemoteInterface (WebSocket)
@property (nonatomic, strong) SRWebSocket *connectionForWebSocket;
@property (nonatomic, strong) NSMutableDictionary *handlerMap;

- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketCallback)successBlock onFailure:(WAWebSocketFailure)failureBlock;

@end
