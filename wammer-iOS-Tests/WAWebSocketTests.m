	//
	//  WAWebSocketTests.m
	//  wammer
	//
	//  Created by jamie on 8/24/12.
	//  Copyright (c) 2012 Waveface. All rights reserved.
	//

#import "WAWebSocketTests.h"

@implementation WAWebSocketTests {
	NSURL *mockWebSocketServer;
	NSDate *asyncWaitUntil;
}

-(void)setUp {
	asyncWaitUntil = [NSDate dateWithTimeIntervalSinceNow:5];
	
	// TODO: create a mock server to handle the requests
	mockWebSocketServer = [NSURL URLWithString:@"ws://localhost:8889"];
	
	[WARemoteInterface sharedInterface].apiKey = @"";
	[WARemoteInterface sharedInterface].userIdentifier = @"";
	[WARemoteInterface sharedInterface].userToken = @"";
}

-(void)tearDown {
//	[[WARemoteInterface sharedInterface] closeWebSocketConnectionWithCode:0 andReason:nil];
}

-(void)testOpenConnectionSuccess {
	__block BOOL complete = NO;
	[[WARemoteInterface sharedInterface] openWebSocketConnectionForUrl:mockWebSocketServer onSucces:^{
			// success
		complete = YES;
	} onFailure:^(NSError *error) {
		complete = YES;
		STFail(@"Websocket connection should be opened successfully.");
	}];
	
	while (complete == NO && [asyncWaitUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:asyncWaitUntil];
	}
	
	if (complete == NO) {
		STFail(@"Websocket connection should be opened on time.");
	}
}

- (void)testOpenConnectionFail {
	__block BOOL complete = NO;

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
}

@end
