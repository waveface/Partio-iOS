//
//  WAPhotoDay+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 12/14/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPhotoDay+WARemoteInterfaceEntitySyncing.h"

@implementation WAPhotoDay (WARemoteInterfaceEntitySyncing)

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
