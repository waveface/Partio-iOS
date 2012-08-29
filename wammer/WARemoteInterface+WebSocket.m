//
//  WARemoteInterface+WebSocket.m
//  wammer
//
//  Created by Shen Steven on 8/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+WebSocket.h"

@interface WARemoteInterface (WebSocket_Private) <SRWebSocketDelegate>

@property (nonatomic, strong) NSURL *urlForWebSocket;

@property (nonatomic, strong) WAWebSocketConnectCallback successHandler;
@property (nonatomic, strong) WAWebSocketConnectFailure failureHandler;

@end

static NSString * const kConnectionForWebSocket = @"-[WARemoteInterface(WebSocket) connectionForWebSocket]";
static NSString * const kUrlForWebSocket = @"-[WARemoteInterface(WebSocket) urlForWebSocket]";
static NSString * const kSuccessHandler = @"-[WARemoteInterface(WebSocket) successHandler]";
static NSString * const kFailureHandler = @"-[WARemoteInterface(WebSocket) failureHandler]";
static NSString * const kHandlerMap = @"-[WARemoteInterface(WebSocket) handlerMap]";


@implementation WARemoteInterface (WebSocket)
@dynamic connectionForWebSocket;

- (void) connectionResponseWithCode:(NSUInteger)code andReason:(NSString*)message
{
	NSLog(@"Websocket connection failure with code: %d and reason: %@", code, message);
}

- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {
	if (![self.urlForWebSocket isEqual:anURL]) {
		self.urlForWebSocket = anURL;
	}
	
	self.successHandler = successBlock;
	self.failureHandler = failureBlock;
	
	WAWebSocketCommandHandler errorHandler = ^(id resp) {
		NSLog(@"Get an error response from we connection: %@", (NSString *) resp);
		NSNumber *retCode = [(NSDictionary*)resp objectForKey:@"api_ret_code"];
		NSString *message = [(NSDictionary*)resp objectForKey:@"api_ret_message"];
		
		if (retCode && ![retCode isEqualToNumber:[NSNumber numberWithInteger:WAWebSocketNormal]])
			[self connectionResponseWithCode:[retCode integerValue] andReason:message];
	};
	
	self.commandHandlerMap = [[NSMutableDictionary alloc] initWithObjectsAndKeys:errorHandler, @"result", nil];
	
	[self.connectionForWebSocket close];
	if (!self.connectionForWebSocket) {
		self.connectionForWebSocket = [[SRWebSocket alloc] initWithURL:self.urlForWebSocket];
	}
	self.connectionForWebSocket.delegate = self;
	[self.connectionForWebSocket open];
}


#pragma mark - getters/setters of instance variables
- (void) setConnectionForWebSocket:(SRWebSocket *)connectionForWebSocket {
	objc_setAssociatedObject(self, &kConnectionForWebSocket, connectionForWebSocket, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SRWebSocket *) connectionForWebSocket {
	return objc_getAssociatedObject(self, &kConnectionForWebSocket);
}

- (void) setCommandHandlerMap:(NSDictionary *)handlerMap {
	objc_setAssociatedObject(self, &kHandlerMap, handlerMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *) commandHandlerMap {
	return objc_getAssociatedObject(self, &kHandlerMap);
}


@end


@implementation WARemoteInterface (WebSocket_Private)
@dynamic urlForWebSocket, successHandler, failureHandler;


#pragma mark - SRWebSocket delegate methods
- (void) webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	[self connectionResponseWithCode:code andReason:reason];
}

- (void) webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	NSLog(@"Fail for a websocket with error: %@", error);
	if (self.failureHandler) {
		self.failureHandler(error);
	}
}

- (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	NSError *error = nil;
	NSLog(@"%@", message);
	NSDictionary *result = [NSJSONSerialization JSONObjectWithData:[(NSString*)message dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];

	if (!result) {
		if (error) {
			NSLog(@"Failed to parse message from ws connection: %@", error);
			
			//FIXME: Fail to parse response JSON?
		}
	} else {
		[result enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			WAWebSocketCommandHandler handler = [self.commandHandlerMap objectForKey:key];
			if (handler != nil) {
				handler(obj);
			} else {
				NSLog(@"Not supported command: %@", (NSString*)key);
			}
		}];
	}
}

- (void) webSocketDidOpen:(SRWebSocket *)webSocket {
	if (self.successHandler) {
		self.successHandler();
	}
}


#pragma mark - getters/setters of instance variables
- (void) setUrlForWebSocket:(NSURL *)urlForWebSocket {
	objc_setAssociatedObject(self, &kUrlForWebSocket, urlForWebSocket, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *) urlForWebSocket {
	return objc_getAssociatedObject(self, &kUrlForWebSocket);
}

- (void) setSuccessHandler:(WAWebSocketConnectCallback)successHandler {
	objc_setAssociatedObject(self, &kSuccessHandler, successHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WAWebSocketConnectCallback) successHandler {
	return objc_getAssociatedObject(self, &kSuccessHandler);
}

- (void) setFailureHandler:(WAWebSocketConnectFailure)failureHandler {
	objc_setAssociatedObject(self, &kFailureHandler, failureHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WAWebSocketConnectFailure) failureHandler {
	return objc_getAssociatedObject(self, &kFailureHandler);
}

@end