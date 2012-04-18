//
//  WAStorage+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 4/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAStorage+WARemoteInterfaceEntitySyncing.h"
#import "WADataStore.h"

@implementation WAStorage (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {

	return @"displayName";

}

+ (BOOL) skipsNonexistantRemoteKey {

	return YES;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"displayName", @"display_name",
			@"intervalEndDate", @"interval.quota_interval_end",
			@"intervalStartDate", @"interval.quota_interval_begin",
			@"numberOfDocumentsAllowedInInterval", @"quota.month_doc_objects",
			@"numberOfDocumentsCreatedInInterval", @"usage.month_doc_objects",
			@"numberOfObjectsAllowedInInterval", @"quota.month_total_objects",
			@"numberOfObjectsCreatedInInterval", @"usage.month_total_objects",
			@"numberOfPicturesAllowedInInterval", @"quota.month_image_objects",
			@"numberOfPicturesCreatedInInterval", @"usage.month_image_objects",
		nil];
		
	});

	return mapping;

}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	//	I don’t know why only this entity gets response in time-since-1970 while all other stuff uses ISO 8601

	if ([aLocalKeyPath isEqualToString:@"intervalStartDate"])
		return [NSDate dateWithTimeIntervalSince1970:[aValue doubleValue]];
		
	if ([aLocalKeyPath isEqualToString:@"intervalEndDate"])
		return [NSDate dateWithTimeIntervalSince1970:[aValue doubleValue]];
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

@end
