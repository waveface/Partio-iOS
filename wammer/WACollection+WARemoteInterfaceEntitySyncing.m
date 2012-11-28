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
#import <JSONKit/JSONKit.h>

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
		@"files": @"WAFile",
		@"creator": @"WAUser",
	};
	

}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = @{
			@"name": @"title",
			@"seq_num": @"sequenceNumber",
			@"files": @"files",
			@"creator": @"creator",
			@"create_time": @"creationDate",
			@"modify_time": @"modificationDate",
			@"collection_id": @"identifier",
			@"hidden": @"isHidden",
			@"smart": @"isSmart",
		};
		
	});
	
	return mapping;
	
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {
	NSMutableDictionary *returnedDictionary = [incomingRepresentation mutableCopy];
	
	NSString *creatorID = [incomingRepresentation objectForKey:@"creator_id"];
	if ([creatorID length])
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:creatorID forKey:@"user_id"]
													 forKey:@"creator"];

	NSArray *incomingAttachmentList;
	if ([[incomingRepresentation objectForKey:@"object_id_list"] isKindOfClass:[NSString class]]) {
		incomingAttachmentList = nil;
	} else {
	  incomingAttachmentList = [[incomingRepresentation objectForKey:@"object_id_list"] copy];
	}
	
	NSMutableArray *returnedAttachmentList = [[NSMutableArray alloc] init];
	
	for (NSString *objectID in incomingAttachmentList) {
    [returnedAttachmentList addObject: @{@"object_id": objectID}];
	}
	
	[returnedDictionary setObject:returnedAttachmentList forKey:@"files"];
	
	return returnedDictionary;
	
}

+ (id) transformedValue:(id)aValue
			fromRemoteKeyPath:(NSString *)aRemoteKeyPath
				 toLocalKeyPath:(NSString *)aLocalKeyPath {
	
	if ([aLocalKeyPath isEqualToString:@"identifier"])
		return IRWebAPIKitStringValue(aValue);
	
	if ([aLocalKeyPath isEqualToString:@"modificationDate"] ||
			[aLocalKeyPath isEqualToString:@"creationDate"] )
		return [NSDate dateFromISO8601String:aValue];
	
	if ([aLocalKeyPath isEqualToString:@"isHidden"] ||
			[aLocalKeyPath isEqualToString:@"isSmart"] )
		return ([aValue isEqual:@"false"] || [aValue isEqual:@"0"] || [aValue isEqual:[NSNumber numberWithInt:0]]) ? (id)kCFBooleanFalse	 : (id)kCFBooleanTrue;
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];
	
}

+ (void)synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {
	
}

+ (void)synchronizeWithCompletion:(WAEntitySyncCallback)block {
	
}

- (void)synchronizeWithCompletion:(WAEntitySyncCallback)block {
		[self synchronizeWithOptions:nil completion:block];
}

- (void)synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {
	
}

@end

