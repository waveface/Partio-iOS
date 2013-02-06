//
//  WAWebSocketTests.m
//  wammer
//
//  Created by jamie on 8/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAWebSocketTests.h"
#import "OCMock/OCMock.h"
#import "WAWebSocket.h"
#import "WARemoteInterface+WebSocket.h"
#import <objc/runtime.h>

@interface WAWebSocket (ForWebSocketTest)

- (void) replaceWebSocketConnection:(SRWebSocket *)newSocketConnection;

@end

@implementation WAWebSocket (ForWebSocketTest)

/* 
 * This should be called before WARemoteInterface:openWebSocketWithURL
 */
- (void) replaceWebSocketConnection:(SRWebSocket *)newSocketConnection
{
	self.connectionForWebSocket = newSocketConnection;
}

- (void) _doConnect
{
	[self.connectionForWebSocket open];
}

@end

@implementation WAWebSocketTests {
	NSURL *mockWebSocketServer;
	NSDate *asyncWaitUntil;
	__block id mockSocket;
	WAWebSocket *webSocket;
}

-(void)setUp {
	asyncWaitUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
	
	// TODO: create a mock server to handle the requests
	mockWebSocketServer = [NSURL URLWithString:@"ws://ws.waveface.com:8889"];
	
	webSocket = [[WAWebSocket alloc] initWithApikey:@"" usertoken:@"" userIdentifier:@""];
		
	SRWebSocket *mock = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://localhost"]];
	mockSocket = [OCMockObject partialMockForObject:mock];
}

-(void)tearDown {
	//	[[WARemoteInterface sharedInterface] closeWebSocketConnectionWithCode:0 andReason:nil];
}

-(void)testOpenConnectionSuccess {
	__block BOOL complete = NO;
	
	__weak WAWebSocket *wSocket = webSocket;
	
	[[[mockSocket expect] andDo:^(NSInvocation *invocation) {
		[wSocket performSelector:@selector(webSocketDidOpen:) withObject:nil];
	}] open];

	[[[mockSocket expect] andDo:^(NSInvocation *invocation) {
		// Do nothing for now
	}] send:[OCMArg any]];
	
	[webSocket replaceWebSocketConnection:(SRWebSocket*)mockSocket];

  [webSocket openConnectionToUrl:mockWebSocketServer onSucces:^{
		 // success
		 complete = YES;
	 }
	 onFailure:^(NSError *error) {
		 complete = YES;
		 STFail(@"Websocket connection should be opened successfully.");
	 }];
	
	while (complete == NO && [asyncWaitUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:asyncWaitUntil];
	}
	
	if (complete == NO) {
		STFail(@"Websocket connection should be opened on time.");
	}
	
	[mockSocket verify]; // All expected method should be called
}


- (void)testOpenConnectionFail {
	__block BOOL complete = NO;

	__weak WAWebSocket *wSocket = webSocket;
	
	[[[mockSocket expect] andDo:^(NSInvocation *invocation) {
		[wSocket performSelector:@selector(webSocket:didFailWithError:) withObject:nil withObject:nil];
	}] open];

	
	[webSocket replaceWebSocketConnection:(SRWebSocket*)mockSocket];

  [webSocket openConnectionToUrl:mockWebSocketServer onSucces:^{
		complete = YES;
		STFail(@"Websocket connection should fail to be opened.");
	} onFailure:^(NSError *error) {
		complete = YES;
		// success
	}];

	while (complete == NO && [asyncWaitUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:asyncWaitUntil];
	}

	if (complete == NO) {
		STFail(@"Websocket connection should be opened on time.");
	}
	
	[mockSocket verify];
}

- (void)testConnectDueToHandShakeError {
	__block BOOL complete = NO;
	
	__weak WAWebSocket *wSocket = webSocket;

	[[[mockSocket expect] andDo:^(NSInvocation *invocation) {
		[wSocket performSelector:@selector(webSocketDidOpen:) withObject:nil];
	}] open];
	
	[[[mockSocket expect] andDo:^(NSInvocation *invocation) {
		[wSocket performSelector:@selector(webSocket:didReceiveMessage:) withObject:nil withObject:@"{\"result\":{\"api_ret_code\":1010,\"api_ret_message\":\"\"}}"];
	}] send:[OCMArg any]];

	[webSocket replaceWebSocketConnection:(SRWebSocket*)mockSocket];
	
  [webSocket openConnectionToUrl:mockWebSocketServer onSucces:^{
		complete = YES;
		// do nothing, socket will be opened successfully but fail with server's response
	} onFailure:^(NSError *error) {
		STAssertNotNil(error, @"Error should be responsed, should not be nil");
		STAssertEquals(error.code, 1010, @"Handshake error code should be 1010 in the error response");
		complete = YES;
		// else success
	}];
	
	while (complete == NO && [asyncWaitUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:asyncWaitUntil];
	}
	
	if (complete == NO) {
		STFail(@"Websocket connection should be opened on time.");
	}
	
	[mockSocket verify];
	
}
 
- (void)testConnectPermissionDeniedError {
	__block BOOL complete = NO;
	
	__weak WAWebSocket *wSocket = webSocket;
	
	[[[mockSocket expect] andDo:^(NSInvocation *invocation) {
		[wSocket performSelector:@selector(webSocketDidOpen:) withObject:nil];
	}] open];
	
	[[[mockSocket expect] andDo:^(NSInvocation *invocation) {
		[wSocket performSelector:@selector(webSocket:didReceiveMessage:) withObject:nil withObject:@"{\"result\":{\"api_ret_code\":1010,\"api_ret_message\":\"\"}}"];
	}] send:[OCMArg any]];
	
	[webSocket replaceWebSocketConnection:(SRWebSocket*)mockSocket];
	
  [webSocket openConnectionToUrl:mockWebSocketServer onSucces:^{
		complete = YES;
		// do nothing, socket will be opened successfully but fail with server's response
	} onFailure:^(NSError *error) {
		STAssertNotNil(error, @"Error should be responsed, should not be nil");
		STAssertEquals(error.code, WAWebSocketPermissionDeniedError, @"Permission denied error should be included in the error response.");
		complete = YES;
		// else success
	}];
	
	while (complete == NO && [asyncWaitUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:asyncWaitUntil];
	}
	
	if (complete == NO) {
		STFail(@"Websocket connection should be opened on time.");
	}
	
	[mockSocket verify];
	
}

@end
