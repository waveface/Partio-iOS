//
//  WADefines.m
//  wammer
//
//  Created by Evadne Wu on 10/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"

void WARegisterUserDefaults () {

	NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"WADefaults" withExtension:@"plist"];
	NSData *defaultsData = [NSData dataWithContentsOfMappedFile:[defaultsURL path]];
	NSDictionary *defaultsObject = [NSPropertyListSerialization propertyListFromData:defaultsData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsObject];

}

NSString * const kWARemoteEndpointURL = @"WARemoteEndpointURL";
NSString * const kWALastAuthenticatedUserTokenKeychainItem = @"WALastAuthenticatedUserTokenKeychainItem";
NSString * const kWALastAuthenticatedUserIdentifier = @"WALastAuthenticatedUserIdentifier";

