//
//  WAOpenGraphElement+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 2/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAOpenGraphElement+WARemoteInterfaceEntitySyncing.h"

@implementation WAOpenGraphElement (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {

	return nil;

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"WAOpenGraphElementImage", @"images",
	
	nil];

}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"providerDisplayName", @"provider_display",
			@"providerName", @"provider_name",
			@"providerURL", @"provider_url",
			//	@"thumbnailURL", @"thumbnail_url",
			@"text", @"description",
			@"title", @"title",
			@"url", @"url",
			@"type", @"type",
			@"images", @"images",
		nil];
		
	});

	return mapping;

}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSArray *incomingImages = [incomingRepresentation objectForKey:@"images"];
	
	if (![incomingImages isKindOfClass:[NSArray array]]) {
	
		//	Bad API
	
		NSString *primaryImageURI = [incomingRepresentation objectForKey:@"thumbnail_url"];
		if (![primaryImageURI isKindOfClass:[NSString class]])
			return incomingRepresentation;
	
		NSMutableDictionary *transformedRepresentation = [incomingRepresentation mutableCopy];
		[transformedRepresentation setObject:[NSArray arrayWithObject:[NSDictionary dictionaryWithObject:primaryImageURI forKey:@"url"]] forKey:@"images"];
		
		return transformedRepresentation;
	
	}

	return incomingRepresentation;

}

@end
