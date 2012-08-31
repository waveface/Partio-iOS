//
//  WARemoteInterface+WebSocket.m
//  wammer
//
//  Created by Shen Steven on 8/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+WebSocket.h"
#import "WARemoteInterfaceDefines.h"
#import "WABackoffHandler.h"

@interface WARemoteInterface (WebSocket_Private) <SRWebSocketDelegate>

@property (nonatomic, strong) NSURL *urlForWebSocket;

@property (nonatomic, strong) WAWebSocketConnectCallback successHandler;
@property (nonatomic, strong) WAWebSocketConnectFailure failureHandler;
@property (nonatomic, strong) WABackoffHandler *backoffHandler;

NSError * WARemoteInterfaceWebSocketError (NSUInteger code, NSString *message);

@end

static NSString * const kConnectionForWebSocket = @"-[WARemoteInterface(WebSocket) connectionForWebSocket]";
static NSString * const kUrlForWebSocket = @"-[WARemoteInterface(WebSocket) urlForWebSocket]";
static NSString * const kSuccessHandler = @"-[WARemoteInterface(WebSocket) successHandler]";
static NSString * const kFailureHandler = @"-[WARemoteInterface(WebSocket) failureHandler]";
static NSString * const kHandlerMap = @"-[WARemoteInterface(WebSocket) handlerMap]";
static NSString * const kBackOffHandler = @"-[WARemoteInterface(WebSocket) backOffHandler]";
static const NSUInteger kWebSocketReconnectInitInterval = 2;

@implementation WARemoteInterface (WebSocket)
@dynamic connectionForWebSocket, webSocketState;

- (NSString *) composeJSONStringForCommand:(NSString*)command withArguments:(NSDictionary *)arguments {
	NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:arguments, command, nil];
	if ([NSJSONSerialization isValidJSONObject:data]) {
		NSError *error = nil;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
		if (jsonData)
			return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	}
	return nil;
}

NSError * WARemoteInterfaceWebSocketError (NSUInteger code, NSString *message) {
	NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
	
	[errorUserInfo setObject:[NSNumber numberWithUnsignedInt:code] forKey:kWARemoteInterfaceRemoteErrorCode];
	[errorUserInfo setObject:message forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:kWARemoteInterfaceDomain code:code userInfo:errorUserInfo];
}

- (void) connectionResponseWithCode:(NSUInteger)code andReason:(NSString*)message
{
	NSLog(@"Websocket connection failure with code: %d and reason: %@", code, message);
	
	switch (code) {
		case WAWebSocketGoingAwayError:
		case WAWebSocketHandshakeError:
			if (self.failureHandler) {
				NSError *error = WARemoteInterfaceWebSocketError(code, message);
				self.failureHandler(error);
			}
			break;
			
		case WAWebSocketAbnormalError:
		case 0: // normally closed
		default: {
			__weak WARemoteInterface *wSelf = self;
			double delayInSeconds = [self.backoffHandler nextInterval];
			
			if (delayInSeconds > 30) {
				if (self.failureHandler) {
					NSError *error = WARemoteInterfaceWebSocketError(WAWebSocketGoingAwayError, @"Unable to connect to websocket server.");
					self.failureHandler(error);
				}
				break;
			}
			
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
				[wSelf reconnectWebSocket];
			});
			break;
		}
	}
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
	
	[self reconnectWebSocket];
}

- (void) closeWebSocketConnectionWithCode:(NSInteger)code andReason:(NSString*)reason
{
	if (self.connectionForWebSocket) {
		self.connectionForWebSocket.delegate = nil;
		[self.connectionForWebSocket closeWithCode:code reason:reason];
	}
}

- (void) reconnectWebSocket
{
	if (self.connectionForWebSocket) {
		// We need to zero out the delegate to prevent an infinite looping hell
		self.connectionForWebSocket.delegate = nil;
		[self.connectionForWebSocket closeWithCode:WAWebSocketNormal reason:@"Normally closed from refresh button"];
		self.connectionForWebSocket = nil;
	}
	self.backoffHandler = [[WABackoffHandler alloc] initWithInitialBackoffInterval:kWebSocketReconnectInitInterval valueFixed:NO];
	self.connectionForWebSocket = [[SRWebSocket alloc] initWithURL:self.urlForWebSocket];
	self.connectionForWebSocket.delegate = self;
	[self.connectionForWebSocket open];	// re-connect
}

#pragma mark - getters/setters of properties
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

- (NSUInteger) webSocketState
{
	if (!self.connectionForWebSocket)
		return WAWebSocketClosed;
	
	if ([self.connectionForWebSocket readyState] == SR_CONNECTING)
		return WAWebSocketConnecting;
	
	if ([self.connectionForWebSocket readyState] == SR_OPEN)
		return WAWebSocketOpen;
	
	if ([self.connectionForWebSocket readyState] == SR_CLOSING)
		return WAWebSocketClosing;
		
	return WAWebSocketClosed;
}

- (BOOL) webSocketConnected
{
	return ((self.connectionForWebSocket) && (self.connectionForWebSocket.readyState == SR_OPEN));
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
	NSDictionary *arguments = [[NSDictionary alloc] initWithObjectsAndKeys: self.apiKey, @"apikey",
																																					self.userToken, @"session_token",
																																				  self.userIdentifier, @"user_id", nil ];
	NSString *cmdString = [self composeJSONStringForCommand:@"connect" withArguments:arguments];
	[self.connectionForWebSocket send:cmdString];
	
	if (self.successHandler) {
		self.successHandler();
	}
}


#pragma mark - getters/setters of properties
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

- (void) setBackoffHandler:(WABackoffHandler *)backoffHandler
{
	objc_setAssociatedObject(self, &kBackOffHandler, backoffHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WABackoffHandler*) backoffHandler
{
	return objc_getAssociatedObject(self, &kBackOffHandler);
}

@end
