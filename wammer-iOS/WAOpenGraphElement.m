//
//  WAOpenGraphElement.m
//  wammer-iOS
//
//  Created by Evadne Wu on 9/8/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAOpenGraphElement.h"


@implementation WAOpenGraphElement

@dynamic providerName;
@dynamic providerURL;
@dynamic text;
@dynamic title;
@dynamic thumbnailFilePath;
@dynamic thumbnailURL;
@dynamic type;
@dynamic url;

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
			@"providerName", @"provider_name",
			@"providerURL", @"provider_url",
			@"thumbnailURL", @"thumbnail_url",
			@"text", @"description",
			@"title", @"title",
			@"url", @"url",
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

@end
