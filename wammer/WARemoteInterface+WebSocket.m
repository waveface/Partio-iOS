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

@property (nonatomic, strong) WAWebSocketCallback successHandler;
@property (nonatomic, strong) WAWebSocketFailure failureHandler;

@end

static NSString * const kConnectionForWebSocket = @"-[WARemoteInterface(WebSocket) connectionForWebSocket]";
static NSString * const kUrlForWebSocket = @"-[WARemoteInterface(WebSocket) urlForWebSocket]";
static NSString * const kSuccessHandler = @"-[WARemoteInterface(WebSocket) successHandler]";
static NSString * const kFailureHandler = @"-[WARemoteInterface(WebSocket) failureHandler]";
static NSString * const kHandlerMap = @"-[WARemoteInterface(WebSocket) handlerMap]";


@implementation WARemoteInterface (WebSocket)
@dynamic connectionForWebSocket;

- (void) openWebSocketConnectionForUrl:(NSURL *)anURL onSucces:(WAWebSocketCallback)successBlock onFailure:(WAWebSocketFailure)failureBlock {
	if (![self.urlForWebSocket isEqual:anURL]) {
		self.urlForWebSocket = anURL;
	}
	
	self.successHandler = successBlock;
	self.failureHandler = failureBlock;
	
	WAWebSocketHandler errorHandler = ^(id resp) {
		NSLog(@"Get an error response from we connection: %@", (NSString *) resp);
	};
	
	self.handlerMap = [[NSMutableDictionary alloc] initWithObjectsAndKeys:errorHandler, @"error", nil];
	
	[self.connectionForWebSocket close];
	self.connectionForWebSocket = [[SRWebSocket alloc] initWithURL:self.urlForWebSocket];
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

- (void) setHandlerMap:(NSDictionary *)handlerMap {
	objc_setAssociatedObject(self, &kHandlerMap, handlerMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary *) handlerMap {
	return objc_getAssociatedObject(self, &kHandlerMap);
}


@end


@implementation WARemoteInterface (WebSocket_Private)
@dynamic urlForWebSocket, successHandler, failureHandler;

#pragma mark - getters/setters of instance variables
- (void) setUrlForWebSocket:(NSURL *)urlForWebSocket {
	objc_setAssociatedObject(self, &kUrlForWebSocket, urlForWebSocket, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *) urlForWebSocket {
	return objc_getAssociatedObject(self, &kUrlForWebSocket);
}

- (void) setSuccessHandler:(WAWebSocketCallback)successHandler {
	objc_setAssociatedObject(self, &kSuccessHandler, successHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WAWebSocketCallback) successHandler {
	return objc_getAssociatedObject(self, &kSuccessHandler);
}

- (void) setFailureHandler:(WAWebSocketFailure)failureHandler {
	objc_setAssociatedObject(self, &kFailureHandler, failureHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WAWebSocketFailure) failureHandler {
	return objc_getAssociatedObject(self, &kFailureHandler);
}

#pragma mark - SRWebSocket delegate methods
- (void) webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	
}

- (void) webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	NSLog(@"Fail for a websocket with error: %@", error);
	if (self.failureHandler) {
		self.failureHandler(error);
	}
}

- (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	NSError *error = nil;
	NSDictionary *result = [NSJSONSerialization JSONObjectWithData:[(NSString*)message dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
	
	if (!result) {
		if (!error) {
			NSLog(@"Failed to parse message from ws connection: %@", error);
			
			// Fail handler??
		}
	} else {
		[result enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			WAWebSocketHandler handler = [self.handlerMap objectForKey:key];
			if (handler != nil) {
				handler(obj);
			} else {
				NSLog(@"Cannot find corresponding handler for command: %@", (NSString*)key);
			}
		}];
	}
}

- (void) webSocketDidOpen:(SRWebSocket *)webSocket {
	if (self.successHandler) {
		self.successHandler();
	}
}


@end