//
//  WAFileAccessLog+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by kchiu on 12/12/12.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFileAccessLog+WARemoteInterfaceEntitySyncing.h"

@implementation WAFileAccessLog (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
	
	return @"accessTime";

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {
	
	return @{
		@"day": @"WADocumentDay",
		@"dayWebpages": @"WAWebpageDay",
	};
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = @{
			@"accessTime": @"accessTime",
			@"accessSource": @"accessSource",
			@"filePath": @"filePath",
			@"day": @"day",
			@"dayWebpages": @"dayWebpages"
		};

	});
	
	return mapping;
	
}

@end
