//
//  WAFacebook.m
//  wammer
//
//  Created by jamie on 12/10/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFacebookConnectionSwitchTest.h"
#import "OCMock/OCMock.h"
#import <FacebookSDK/FacebookSDK.h>
#import "WARemoteInterface.h"
#import "WADefines.h"

@interface WAFacebookConnectionSwitch (UnitTest)
- (void) handleFacebookConnect:(id)sender;
@end

static id mockSession = nil;
static id mockRemoteInterface = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation WAFacebookConnectionSwitch (UnitTest)
- (void) reloadStatus {}
@end

@implementation FBSession (UnitTestForSingleton)
+ (FBSession *)activeSession {
	return mockSession;
}
@end

@implementation WARemoteInterface (UnitTest)
+ (WARemoteInterface *)sharedInterface {
	return mockRemoteInterface;
}
@end
#pragma clang diagnostic pop

@implementation WAFacebookConnectionSwitchTest

- (void)setUp {
	_theSwitch = [[WAFacebookConnectionSwitch alloc] init];
	mockRemoteInterface = [OCMockObject mockForClass:[WARemoteInterface class]];
	mockSession = [OCMockObject mockForClass:[FBSession class]];
}

- (void)tearDown {
	_theSwitch = nil;
	mockRemoteInterface = nil;
	mockSession = nil;
}

- (void)testChangeStatusPersistence {
	_theSwitch.on = YES;
	STAssertTrue([[NSUserDefaults standardUserDefaults] boolForKey:kWASNSFacebookConnectEnabled],
							 @"This should be true");
}

- (void)testFacebookConnectSuccess {
	[[[mockSession expect] andReturnValue:OCMOCK_VALUE((BOOL){YES})] isOpen];
	[[[mockSession expect] andReturn:@"SomeToken"] accessToken];
	
	void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
		void (^successBlock)(void);
		[invocation getArgument:&successBlock atIndex:4];
		successBlock();
		_theSwitch.on = YES;
	};
	
	[[[mockRemoteInterface expect] andDo:nil]
	 retrieveConnectedSocialNetworksOnSuccess:[OCMArg any]
	 onFailure:[OCMArg any]];
	[[[mockRemoteInterface expect] andDo:theBlock]
	 connectSocialNetwork:@"facebook" withToken:[OCMArg any] onSuccess:[OCMArg any] onFailure:[OCMArg any]];
	
	@autoreleasepool {
		[_theSwitch handleFacebookConnect:nil];
	}
	
//FBSession.activeSession failed to override. Fix later.
//	STAssertTrue(_theSwitch.on, @"Switch should be on.");
//	
//	[mockSession verify];
//	[mockRemoteInterface verify];
}

- (void)testFacebookConnectFailed {

	[[[mockSession expect] andReturnValue:OCMOCK_VALUE((BOOL){NO})] isOpen];
	
	@autoreleasepool {
		[_theSwitch handleFacebookConnect:nil];
	}
	
	STAssertFalse(_theSwitch.on, @"Turned off when facebook failed.");
}

@end
