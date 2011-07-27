//
//  WAFile.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAFile.h"
#import "WAArticle.h"
#import "WAUser.h"
#import "WADataStore.h"


@implementation WAFile

@dynamic identifier;
@dynamic resourceFilePath;
@dynamic resourceType;
@dynamic resourceURL;
@dynamic text;
@dynamic thumbnailFilePath;
@dynamic thumbnailURL;
@dynamic timestamp;
@dynamic article;
@dynamic owner;

+ (NSString *) keyPathHoldingUniqueValue {

	return @"identifier";

}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"identifier", @"id",
			@"text", @"text",
			@"thumbnailURL", @"thumbnail_url",
			@"resourceURL", @"url",
			@"resourceType", @"type",
			@"timestamp", @"timestamp",
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	if ([aLocalKeyPath isEqualToString:@"timestamp"])
		return [[WADataStore defaultStore] dateFromISO8601String:aValue];
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

@end
