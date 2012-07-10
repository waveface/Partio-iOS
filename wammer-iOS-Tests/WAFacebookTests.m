//
//  WAFacebookTests.m
//  wammer
//
//  Created by jamie on 7/3/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFacebookTests.h"
#import "FBConnect.h"

@interface MockFacebookDelegate : NSObject <FBSessionDelegate>

@end

@implementation MockFacebookDelegate


@end

@interface Facebook (Singleton) <FBSessionDelegate>
+ (Facebook *) sharedInstance;
@end

@implementation Facebook (Singleton)

+ (Facebook *)sharedInstanceWithDelegate: (id<FBSessionDelegate>) delegate{
	static Facebook *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[Facebook alloc] initWithAppId:@"357087874306060" andDelegate:delegate];
	});
	
	sharedInstance.sessionDelegate = delegate;
	
	return sharedInstance;
}

@end

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

@end

