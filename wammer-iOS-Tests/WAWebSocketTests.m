	//
	//  WAWebSocketTests.m
	//  wammer
	//
	//  Created by jamie on 8/24/12.
	//  Copyright (c) 2012 Waveface. All rights reserved.
	//

#import "WAWebSocketTests.h"

@implementation WAWebSocketTests {
	SRWebSocket *webSocket;
	NSInteger retCode;
}

-(void)setUp {
	webSocket = [[SRWebSocket alloc] initWithURLRequest:
							 [NSURLRequest requestWithURL:
								[NSURL URLWithString:@"ws://192.168.1.250:8009"]]];
	webSocket.delegate = self;
}

-(void)tearDown {
	[webSocket close];
	webSocket = nil;
}

-(void)testOpenConnection {
	[webSocket open];
	
	
	NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:10];
	while ([loopUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
														 beforeDate:loopUntil];
	}
	
	NSString *message = @"Mary has a little lamb.";
	[webSocket send:message];
	
	loopUntil = [NSDate dateWithTimeIntervalSinceNow:10];
	while ([loopUntil timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
														 beforeDate:loopUntil];
	}
	
	NSLog(@"%@", webSocket);
	STAssertEquals((NSInteger)3000, retCode, @"Did recieve return code");
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	NSLog(@"%@", message);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	NSLog(@"*** Code %d", code);
	retCode = code;
}

- (void)webSocketDidOpen:(SRWebSocket *)aWebSocket {
	NSLog(@"%@ Web Socket Opened!", aWebSocket);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	NSLog(@"Failed with %@", error.description);
}
@end
