//
//  WADocumentDay+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by kchiu on 12/12/12.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WADocumentDay+WARemoteInterfaceEntitySyncing.h"
#import <NSDate+SSToolkitAdditions.h>

@implementation WADocumentDay (WARemoteInterfaceEntitySyncing)

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
