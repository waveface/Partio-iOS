//
//  Facebook+Singleton.m
//  wammer
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "Facebook+Singleton.h"

@interface Facebook (SingletonPrivate) {
}

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

/*
 authorize user with Stream required permission with store them in NSUserDefaults.
 */
- (void) authorize {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:kFBAccessTokenKey] && [defaults objectForKey:kFBExpirationDateKey]) {
		self.accessToken = [defaults objectForKey:kFBAccessTokenKey];
		self.expirationDate = [defaults objectForKey:kFBExpirationDateKey];
	}
	
	if (![self isSessionValid]) {
		// https://docs.google.com/a/waveface.com/document/d/1ITd_aVoN6Kowo1H52wVY3C1zFtvQeRO8YfrFy2hyH0w/edit#
		[self authorize:[NSArray arrayWithObjects:@"email", @"user_photos", @"user_videos", @"user_notes", @"user_status", @"read_stream", nil]];
	}
	
}


#pragma FBSessionDelegate Methods

- (void)fbDidLogin {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[self accessToken] forKey:kFBAccessTokenKey];
	[defaults setObject:[self expirationDate] forKey:kFBExpirationDateKey];

}

@end
