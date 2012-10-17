//
//  WAFacebook.m
//  wammer
//
//  Created by jamie on 12/10/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFacebookTest.h"
#import "OCMock/OCMock.h"
#import <FacebookSDK/FacebookSDK.h>

static id mockSession = nil;

@implementation FBSession (UnitTestForSingleton)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
+ (FBSession *)activeSession {		
	return mockSession;
}
#pragma clang diagnostic pop

@end

@interface WAFacebookConnectionSwitch (UnitTest)
- (void) handleFacebookConnect:(id)sender;
@end

@implementation WAFacebookTest {
}

- (void)setUp {
	_theSwitch = [[WAFacebookConnectionSwitch alloc] init];
}

- (void)tearDown {
	_theSwitch = nil;
}

- (void)testChangeStatusPersistence {
	_theSwitch.on = YES;
	STAssertTrue([[NSUserDefaults standardUserDefaults] boolForKey:kWAFacebookUserDataImport],
							 @"This should be true");
}

- (void)testFacebookTokenValid {
	mockSession = [OCMockObject mockForClass:[FBSession class]];
	[[[mockSession expect] andReturnValue:OCMOCK_VALUE((BOOL){YES})] isOpen];
	[[[mockSession expect] andReturn:@"SomeToken"] accessToken];
	
	[_theSwitch handleFacebookConnect:nil];
	
	STAssertTrue(_theSwitch.on, @"Session Should be on.");
	[mockSession verify];
}

@end
