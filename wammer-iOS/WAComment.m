//
//  WAComment.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAComment.h"
#import "WAArticle.h"
#import "WAUser.h"
#import "WADataStore.h"


@implementation WAComment

@dynamic creationDeviceName;
@dynamic identifier;
@dynamic text;
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
			@"creationDeviceName", @"creation_device_name",
			@"identifier", @"id",
			@"text", @"text",
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
