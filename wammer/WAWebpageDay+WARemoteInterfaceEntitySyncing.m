//
//  WAWebpageDay+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 12/18/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAWebpageDay+WARemoteInterfaceEntitySyncing.h"

@implementation WAWebpageDay (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
	
	return @"day";
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = @{
		@"day": @"day"
		};
		
	});
	
	return mapping;
	
}

@end
