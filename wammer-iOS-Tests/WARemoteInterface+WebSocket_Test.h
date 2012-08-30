//
//  WARemoteInterface+WebSocket_Test.h
//  wammer
//
//  Created by Shen Steven on 8/30/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"
#import "SocketRocket/SRWebSocket.h"

@interface WARemoteInterface (WebSocket_Test)

- (void) replaceWebSocketConnection:(SRWebSocket *)newSocketConnection;
- (void) reconnectWebSocket_override;

@end
