//
//  WAPreview.m
//  wammer-iOS
//
//  Created by Evadne Wu on 9/8/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAPreview.h"
#import "WAArticle.h"
#import "WAUser.h"
#import "WAOpenGraphElement.h"

#import "WADataStore.h"


@implementation WAPreview

@dynamic htmlSynopsis;
@dynamic identifier;
@dynamic text;
@dynamic url;
@dynamic article;
@dynamic graphElement;
@dynamic owner;
@dynamic timestamp;

+ (NSString *) keyPathHoldingUniqueValue {

	return @"identifier";

}

+ (BOOL) skipsNonexistantRemoteKey {

	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

//	[super configureWithRemoteDictionary:inDictionary];
//	
//	NSDictionary *graphRep = [inDictionary objectForKey:@"og"];
//	
//	if (graphRep) {
//		if (!self.graphElement)
//			self.graphElement = [WAOpenGraphElement objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:graphRep];
//		else
//			[self.graphElement configureWithRemoteDictionary:graphRep];
//	}
//	
//	}

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
			@"identifier", @"id",
			@"htmlSynopsis", @"soul",
			@"timestamp", @"timestamp",
			@"text", @"text",
			@"graphElement", @"og",
		nil];
		
		[mapping retain];
		
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
		
		[mapping retain];
		
	});

	return mapping;
	
}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	if ([aLocalKeyPath isEqualToString:@"timestamp"])
		return [[WADataStore defaultStore] dateFromISO8601String:aValue];
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

@end
