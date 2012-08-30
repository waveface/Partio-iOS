//
//  WARemoteInterface+WebSocket_Test.m
//  wammer
//
//  Created by Shen Steven on 8/30/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+WebSocket.h"
#import "WARemoteInterface+WebSocket_Test.h"


@implementation WARemoteInterface (WebSocket_Test)

+ (void)load
{
	/* MethodSwizzling
	 * We need to replace the original recoonectWebSocket method to force WARemoteInterface to use our own
	 * mock WebSocket object instead. So then, we can hook on our own WebSocket mock object and simulate any
	 * response for our testing scenario.
	 */
	
	Method origMethod = class_getInstanceMethod(self, @selector(reconnectWebSocket));
	Method newMethod = class_getInstanceMethod(self, @selector(reconnectWebSocket_override));
	
	method_setImplementation(origMethod, method_getImplementation(newMethod));
}

- (void) replaceWebSocketConnection:(SRWebSocket *)newSocketConnection
{
	/* This should be called before WARemoteInterface:openWebSocketWithURL
	 */
	self.connectionForWebSocket = newSocketConnection;
}

- (void) reconnectWebSocket_override
{
	[self.connectionForWebSocket open];
}


@end
