//
//  WAComment+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 11/15/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADataStore.h"
#import "WAComment+WARemoteInterfaceEntitySyncing.h"

@implementation WAComment (WARemoteInterfaceEntitySyncing)

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSMutableDictionary *transformedRepresentation = [incomingRepresentation mutableCopy];
	NSString *foundCreatorID = [transformedRepresentation valueForKeyPath:@"creator_id"];

	if ([foundCreatorID isKindOfClass:[NSString class]])
		[transformedRepresentation setObject:[NSDictionary dictionaryWithObject:foundCreatorID forKey: @"user_id"] forKey:@"owner"];

	return transformedRepresentation;

}

+ (NSString *) keyPathHoldingUniqueValue {

	return @"identifier";

}

+ (BOOL) skipsNonexistantRemoteKey {

	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"creationDeviceName", @"code_name",
			@"identifier", @"comment_id",
			@"text", @"content",
			@"timestamp", @"timestamp",
			@"owner", @"owner",
			@"article", @"article",
		nil];
		
	});

	return mapping;

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"WAUser", @"owner",
			@"WAArticle", @"article",
		nil];
		
	});

	return mapping;
	
}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	if ([aLocalKeyPath isEqualToString:@"timestamp"])
		return [[WADataStore defaultStore] dateFromISO8601String:aValue];
	
	if ([aLocalKeyPath isEqualToString:@"identifier"])
		return IRWebAPIKitStringValue(aValue);
		
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

@end
