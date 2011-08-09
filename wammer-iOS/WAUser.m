//
//  WAUser.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAUser.h"


@implementation WAUser

@dynamic avatar;
@dynamic avatarURL;
@dynamic email;
@dynamic identifier;
@dynamic nickname;
@dynamic articles;
@dynamic comments;
@dynamic files;

+ (NSString *) keyPathHoldingUniqueValue {

	return @"identifier";

}

+ (BOOL) skipsNonexistantRemoteKey {

	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"avatarURL", @"avatar_url",
			@"identifier", @"id",
			@"nickname", @"nickname",
			@"email", @"email",
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

@end
