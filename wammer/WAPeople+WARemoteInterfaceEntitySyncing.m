//
//  WAPeople+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 11/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPeople+WARemoteInterfaceEntitySyncing.h"

@implementation WAPeople (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
	
	return @"email";
	
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
                   @"name", @"name",
                   @"email", @"email",
                   @"avatarURL", @"avatar_url",
                   @"avatarURL", @"avatar",
                   nil];
		
	});
	
	return mapping;
	
}

@end
