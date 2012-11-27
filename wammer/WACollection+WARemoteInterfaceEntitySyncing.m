//
//  WACollection+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by jamie on 12/11/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACollection+WARemoteInterfaceEntitySyncing.h"
#import "IRWebAPIKit.h"
#import <SSToolkit/NSDate+SSToolkitAdditions.h>

@implementation WACollection (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
	
	return @"identifier";
	
}

+ (BOOL) skipsNonexistantRemoteKey {
	
	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

+ (NSDictionary *) defaultHierarchicalEntityMapping {
	
	return @{
//		@"files": @"WAFiles",
		@"creator": @"WAUser",
	};
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = @{
			@"name": @"title",
//			@"seq_num": @"sequenceNumber",
//			@"object_id_list": @"files",
//			@"creator_id": @"creator",
			@"create_time": @"createDate",
			@"modify_time": @"modifyDate",
			@"collection_id": @"identifier",
//			@"hidden": @"isHidden",
//			@"smart": @"isSmart",
		};
		
	});
	
	return mapping;
	
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {
	NSMutableDictionary *returnedDictionary = [incomingRepresentation mutableCopy];
	
	NSString *creatorID = [incomingRepresentation objectForKey:@"creator_id"];
	if ([creatorID length])
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:creatorID forKey:@"user_id"] forKey:@"creator"];

	return returnedDictionary;
	
}

- (void) configureWithRemoteDictionary:(NSDictionary *)inDictionary {
	
	[super configureWithRemoteDictionary:inDictionary];
	
	
}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {
	
	if ([aLocalKeyPath isEqualToString:@"identifier"])
		return IRWebAPIKitStringValue(aValue);
	
	if ([aLocalKeyPath isEqualToString:@"modifyDate"] ||
			[aLocalKeyPath isEqualToString:@"createDate"] )
		return [NSDate dateFromISO8601String:aValue];
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];
	
}

- (void)synchronizeWithCompletion:(WAEntitySyncCallback)block {
	
}

- (void)synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {
	
}

@end

