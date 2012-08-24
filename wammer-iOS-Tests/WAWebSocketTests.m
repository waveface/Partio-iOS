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
}

-(void)setUp {
	webSocket = [[SRWebSocket alloc] initWithURLRequest:
							 [NSURLRequest requestWithURL:
								[NSURL URLWithString:@"ws://192.168.1.250:8010"]]];
	webSocket.delegate = self;
}

-(void)tearDown {
	[webSocket close];
	webSocket = nil;
}

-(void)testOpenConnection {
	[webSocket open];
	
		//NSString *message = @"Mary has a little lamb.";
		//[webSocket send:message];
	
	
	NSLog(@"%@", webSocket);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	NSLog(@"%@", message);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	NSLog(@"%d", code);
}

- (void)webSocketDidOpen:(SRWebSocket *)aWebSocket {
	NSLog(@"%@ Web Socket Opened!", aWebSocket);
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	NSLog(@"Failed with %@", error.description);
}
@end
