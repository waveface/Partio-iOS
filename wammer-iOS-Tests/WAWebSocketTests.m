//
//  WAWebSocketTests.m
//  wammer
//
//  Created by jamie on 8/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAWebSocketTests.h"
#import "OCMock/OCMock.h"
#import "WARemoteInterface+WebSocket.h"
#import "WARemoteInterface+WebSocket_Test.h"
#import <objc/objc-class.h>

@implementation WAWebSocketTests {
	NSURL *mockWebSocketServer;
	NSDate *asyncWaitUntil;
	__block id mockSocket;
	WARemoteInterface *remoteInterface;
}


-(void)setUp {
	asyncWaitUntil = [NSDate dateWithTimeIntervalSinceNow:5];
	
	// TODO: create a mock server to handle the requests
	mockWebSocketServer = [NSURL URLWithString:@"ws://ws.waveface.com:8889"];
	
	
	remoteInterface = [WARemoteInterface sharedInterface];
	remoteInterface.apiKey = @"";
	remoteInterface.userIdentifier = @"";
	remoteInterface.userToken = @"";
	
	SRWebSocket *webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://localhost"]];
	mockSocket = [OCMockObject partialMockForObject:webSocket];
}

-(void)tearDown {
	//	[[WARemoteInterface sharedInterface] closeWebSocketConnectionWithCode:0 andReason:nil];
}

-(void)testOCMock {
	
	NSString *string = @"This is a real.";
	id mockString = [OCMockObject partialMockForObject:string];
	[[[mockString stub] andReturn:@"This is a mock."] lowercaseString];
	STAssertEquals([mockString lowercaseString], @"This is a mock.", @"Mocked");
	
}

-(void)testOpenConnectionSuccess {
	__block BOOL complete = NO;
	__weak WARemoteInterface *wRi = remoteInterface;
	
	[[[mockSocket stub] andDo:^(NSInvocation *invocation) {
		[wRi performSelector:@selector(webSocketDidOpen:) withObject:nil];
	}] open];

	[[[mockSocket stub] andDo:^(NSInvocation *invocation) {
		// Do nothing for now
	}] send:[OCMArg any]];
	
	[remoteInterface replaceWebSocketConnection:(SRWebSocket*)mockSocket];

	[[WARemoteInterface sharedInterface]
	 openWebSocketConnectionForUrl:mockWebSocketServer
	 onSucces:^{
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
	
	__weak WARemoteInterface *wRi = remoteInterface;
	
	[[[mockSocket stub] andDo:^(NSInvocation *invocation) {
		[wRi performSelector:@selector(webSocket:didFailWithError:) withObject:nil withObject:nil];
	}] open];
	
	[remoteInterface replaceWebSocketConnection:(SRWebSocket*)mockSocket];

	[[WARemoteInterface sharedInterface] openWebSocketConnectionForUrl:mockWebSocketServer onSucces:^{
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

- (void) testConnectDueToHandShakeError {
	__block BOOL complete = NO;
	
	__weak WARemoteInterface *wRi = remoteInterface;
	
	[[[mockSocket stub] andDo:^(NSInvocation *invocation) {
		[wRi performSelector:@selector(webSocketDidOpen:) withObject:nil];
	}] open];
	
	[[[mockSocket stub] andDo:^(NSInvocation *invocation) {
		[wRi performSelector:@selector(webSocket:didReceiveMessage:) withObject:nil withObject:@"{\"result\":{\"api_ret_code\":1010,\"api_ret_message\":\"\"}}"];
	}] send:[OCMArg any]];

	
	[remoteInterface replaceWebSocketConnection:(SRWebSocket*)mockSocket];
	
	[[WARemoteInterface sharedInterface] openWebSocketConnectionForUrl:mockWebSocketServer onSucces:^{
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
 

@end
