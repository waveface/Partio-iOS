//
//  WALocation+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 11/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALocation+WARemoteInterfaceEntitySyncing.h"

@implementation WALocation (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
	
	return nil;
	
}

+ (BOOL) skipsNonexistantRemoteKey {
	
	return YES;
	
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	return [super transformedRepresentationForRemoteRepresentation:incomingRepresentation];
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"latitude", @"latitude",
							 @"longitude", @"longitude",
							 @"name", @"name",
							 @"zoom_level", @"zoomLevel",
							 nil];
		
	});
	
	return mapping;
	
}

@end
