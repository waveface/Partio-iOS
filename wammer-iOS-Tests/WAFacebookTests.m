//
//  WAFacebookTests.m
//  wammer
//
//  Created by jamie on 7/3/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFacebookTests.h"
#import "Facebook+Singleton.h"

@interface MockFacebookDelegate : NSObject <FBSessionDelegate>

@end

@implementation MockFacebookDelegate


@end

#import "FBConnect.h"

//@interface Facebook (Singleton) <FBSessionDelegate>
//+ (Facebook *) sharedInstance;
//- (void) authorize;
//@end
//
//@implementation Facebook (Singleton)
//
//+ (Facebook *)sharedInstanceWithDelegate: (id<FBSessionDelegate>) delegate{
//	static Facebook *sharedInstance = nil;
//	static dispatch_once_t onceToken;
//	dispatch_once(&onceToken, ^{
//		sharedInstance = [[Facebook alloc] initWithAppId:@"357087874306060" andDelegate:delegate];
//	});
//	
//	sharedInstance.sessionDelegate = delegate;
//	
//	return sharedInstance;
//}
//
///*
//  authorize user with Stream required permission with store them in NSUserDefaults.
//*/
//- (void) authorize {
//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//	if ([defaults objectForKey:kFBAccessTokenKey] && [defaults objectForKey:kFBExpirationDateKey]) {
//		self.accessToken = [defaults objectForKey:kFBAccessTokenKey];
//		self.expirationDate = [defaults objectForKey:kFBExpirationDateKey];
//	}
//
//	if (![self isSessionValid]) {
//		// https://developers.facebook.com/docs/authentication/permissions/
//		[self authorize:[NSArray arrayWithObjects:@"read_stream", nil]];
//	}
//}
//@end

@implementation WAFacebookTests {
	Facebook *facebook;
	MockFacebookDelegate *delegate;
}

- (void)setUp {
	delegate = [[MockFacebookDelegate alloc]init];
	facebook = [Facebook sharedInstanceWithDelegate:delegate];
}
- (void)testSingleton {
	Facebook *aFacebook = [Facebook sharedInstanceWithDelegate:delegate];
	STAssertEqualObjects(facebook, aFacebook, @"Should be same object");
}
//
//- (void)testAuthorization {
//	[facebook authorize];
//	STAssertTrue(facebook.isSessionValid, @"authorized");
//}

@end

