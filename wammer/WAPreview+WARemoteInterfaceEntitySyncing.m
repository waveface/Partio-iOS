//
//  WAPreview+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 2/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPreview+WARemoteInterfaceEntitySyncing.h"
#import "WADataStore.h"

@implementation WAPreview (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {

	return @"url";

}

+ (BOOL) skipsNonexistantRemoteKey {

	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	//	incomingRepresentation should be an open graph element
	//	But we are converting it to a correct thing
	
	return [super transformedRepresentationForRemoteRepresentation:incomingRepresentation];

}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
		//	@"identifier", @"id",
			@"htmlSynopsis", @"soul",
			@"timestamp", @"timestamp",
			@"text", @"text",
			@"graphElement", @"og",
		nil];
		
	});

	return mapping;

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"WAOpenGraphElement", @"og",
		nil];
		
	});

	return mapping;
	
}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	if ([aLocalKeyPath isEqualToString:@"timestamp"])
		return [[WADataStore defaultStore] dateFromISO8601String:aValue];
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

@end
