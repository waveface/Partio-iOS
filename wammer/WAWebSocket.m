//
//  WAWebSocket.m
//  wammer
//
//  Created by Shen Steven on 9/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"
#import "WAWebSocket.h"
#import "WARemoteInterfaceDefines.h"

NSString * composeWSJSONCommand (NSString *command, NSDictionary *arguments) {
	NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:arguments, command, nil];
	if ([NSJSONSerialization isValidJSONObject:data]) {
		NSError *error = nil;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
		if (jsonData)
			return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	}
	return nil;
	
}

static NSUInteger kReconnectRetryMaxCounting = 5;

@interface WAWebSocket ()

@property (nonatomic, strong) WAWebSocketConnectCallback successHandler;
@property (nonatomic, strong) WAWebSocketConnectFailure failureHandler;
@property (nonatomic, strong) NSURL *urlForWebSocket;


NSError * WARemoteInterfaceWebSocketError (NSUInteger code, NSString *message);

@end

@implementation WAWebSocket {
	NSInteger connectRetryCounting;
	BOOL stopped;
}

- (id) initWithUrl:(NSURL*) anURL apikey:(NSString*)theApiKey usertoken:(NSString*)theUserToken userIdentifier:(NSString*)theUserIdentifier {
	self = [super init];
	self.urlForWebSocket = anURL;
	self.userIdentifier = theUserIdentifier;
	self.userToken = theUserToken;
	self.apiKey = theApiKey;
	
	connectRetryCounting = kReconnectRetryMaxCounting;
	stopped = NO;
		
	return self;
}


- (void) openConnectionOnSucces:(WAWebSocketConnectCallback)successBlock onFailure:(WAWebSocketConnectFailure)failureBlock {
	self.successHandler = successBlock;
	self.failureHandler = failureBlock;

	connectRetryCounting = kReconnectRetryMaxCounting;
	stopped = NO;
	
	__weak id wSelf = self;
	WAWebSocketCommandHandler errorHandler = ^(id resp) {
		NSLog(@"Get an error response from we connection: %@", (NSString *) resp);
		NSNumber *retCode = [(NSDictionary*)resp objectForKey:@"code"];
		NSString *message = [(NSDictionary*)resp objectForKey:@"reason"];
		
		if (retCode && ![retCode isEqualToNumber:[NSNumber numberWithInteger:WAWebSocketNormal]])
			[wSelf connectionResponseWithCode:[retCode integerValue] andReason:message];
	};
	
	self.commandHandlerMap = [[NSMutableDictionary alloc] initWithObjectsAndKeys:errorHandler, @"error", nil];

	[self _doConnect];
	
}

- (void) _doConnect {

	self.connectionForWebSocket = [[SRWebSocket alloc] initWithURL:self.urlForWebSocket];
	self.connectionForWebSocket.delegate = self;
	[self.connectionForWebSocket open];
	
}

- (void) dealloc {
	
	[self closeConnectionWithCode:WAWebSocketNormal andReason:@"Normally close websocket"];

}

- (void) closeConnectionWithCode:(NSInteger)code andReason:(NSString*)reason {
	
	stopped = YES;
	if ([self webSocketConnected]) {
		[self.connectionForWebSocket closeWithCode:code reason:reason];
	}
	
}

- (void) reconnectWebSocket
{

	static NSString *const aReason = @"a normal close";
	
	if (self.connectionForWebSocket) {
		if (stopped) {
			[self.connectionForWebSocket closeWithCode:WAWebSocketNormal reason:aReason];
			return;
		}
		// Todo: Ask Steven for this ..
//		[self.connectionForWebSocket reconnectWithCode:WAWebSocketNormal reason:aReason];
	
	}
	
}

- (void) connectionResponseWithCode:(NSUInteger)code andReason:(NSString*)message
{
	NSLog(@"Websocket connection failure with code: %d and reason: %@", code, message);
	
	switch (code) {
		case WAWebSocketGoingAwayError:
		case WAWebSocketHandshakeError:
		case WAWebSocketPermissionDeniedError:
			if (self.failureHandler) {
				NSError *error = WARemoteInterfaceWebSocketError(code, message);
				self.failureHandler(error);
			}
			break;
			
		case WAWebSocketAbnormalError:
		case 0: // normally closed
		default: {
			__weak WAWebSocket *wSelf = self;
			double delayInSeconds = 2;

			if (connectRetryCounting <= 0) {
				connectRetryCounting = kReconnectRetryMaxCounting;
				
				if (self.failureHandler) {
					NSError *error = WARemoteInterfaceWebSocketError(WAWebSocketGoingAwayError, @"Unable to connect to websocket server.");
					self.failureHandler(error);
				}
			
				break;
			}

			connectRetryCounting --;
			
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
				[wSelf reconnectWebSocket];
			});
			
			break;
		}
	}
}

- (void) send:(id)data {
	[self.connectionForWebSocket send:data];
}

- (WAWebSocketState) webSocketState
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

NSError * WARemoteInterfaceWebSocketError (NSUInteger code, NSString *message) {
	NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
	
	[errorUserInfo setObject:[NSNumber numberWithUnsignedInt:code] forKey:kWARemoteInterfaceRemoteErrorCode];
	[errorUserInfo setObject:message forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:kWARemoteInterfaceDomain code:code userInfo:errorUserInfo];
}


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

			dispatch_async(dispatch_get_main_queue(), ^{
				
				WAWebSocketCommandHandler handler = [self.commandHandlerMap objectForKey:key];
				if (handler != nil) {
					handler(obj);
				} else {
					NSLog(@"Not supported command: %@", (NSString*)key);
				}
				
			});
			
		}];
	}
}

- (void) webSocketDidOpen:(SRWebSocket *)webSocket {
	NSDictionary *arguments = [[NSDictionary alloc] initWithObjectsAndKeys: self.apiKey, @"apikey",
														 self.userToken, @"session_token",
														 self.userIdentifier, @"user_id", nil ];
	NSString *cmdString = composeWSJSONCommand(@"connect", arguments);
	[self.connectionForWebSocket send:cmdString];
	
	connectRetryCounting = kReconnectRetryMaxCounting;
	
	if (self.successHandler) {
		self.successHandler();
	}
}


@end
