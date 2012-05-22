//
//  WAOpenGraphElement+WAAdditions.m
//  wammer
//
//  Created by Evadne Wu on 2/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAOpenGraphElement+WAAdditions.h"
#import "IRRemoteResourcesManager.h"
#import "WADataStore.h"
#import "CoreData+IRAdditions.h"
#import "WAOpenGraphElementImage.h"
#import "WAOpenGraphElementImage+WAAdditions.h"


@interface WAOpenGraphElement (WAAdditions_OrderedCollections)

- (WAOpenGraphElementImage *) openGraphElementImageAtIndex:(NSUInteger)anIndex;

@end

@implementation WAOpenGraphElement (WAAdditions_OrderedCollections)

- (WAOpenGraphElementImage *) openGraphElementImageAtIndex:(NSUInteger)anIndex {

	return (WAOpenGraphElementImage *)[self irObjectAtIndex:anIndex inArrayKeyed:@"imageOrder"];

}

@end


@implementation WAOpenGraphElement (WAAdditions)

+ (void) load {

	[self configureSimulatedOrderedRelationship];

}

+ (NSString *) keyPathHoldingUniqueValue {

	return @"url";

}

+ (NSSet *) keyPathsForValuesAffectingImages {

	return [NSSet setWithObjects:@"imageOrder", nil];

}

+ (NSSet *) keyPathsForValuesAffectingImageOrder {

	return [NSSet setWithObjects:@"images", nil];

}

+ (NSDictionary *) orderedRelationships {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"imageOrder", @"images",
		
	nil];

}

+ (BOOL) skipsNonexistantRemoteKey {

	return YES;
	
}

+ (NSSet *) keyPathsForValuesAffectingRepresentedImage {

	return [NSSet setWithObject:@"imageOrder.@count"];

}

- (WAOpenGraphElementImage *) representedImage {

	if (![self.imageOrder count])
		return nil;
	
	return [self openGraphElementImageAtIndex:0];

}

+ (NSSet *) keyPathsForValuesAffectingThumbnail {

	return [NSSet setWithObject:@"representedImage.image"];

}

- (UIImage *) thumbnail {

	return [self representedImage].image;

}

+ (NSSet *) keyPathsForValuesAffectingThumbnailURL {

	return [NSSet setWithObjects:
	
		@"representedImage",
		@"representedImage.imageRemoteURL",
				
	nil];

}

- (NSString *) thumbnailURL {

	return [self representedImage].imageRemoteURL;
}

+ (NSSet *) keyPathsForValuesAffectingThumbnailFilePath {

	return [NSSet setWithObjects:
	
		@"representedImage",
		@"representedImage.imageFilePath",
		
	nil];

}

- (NSString *) thumbnailFilePath {

	return [self representedImage].imageFilePath;
	
}

+ (NSSet *) keyPathsForValuesAffectingProviderCaption {

	return [NSSet setWithObjects:
	
		@"providerName",
		@"providerDisplayName",
		@"providerURL",
	
	nil];

}

- (NSString *) providerCaption {

	if (self.providerName && self.providerDisplayName)
		return [NSString stringWithFormat:@"%@ (%@)", self.providerName, self.providerDisplayName];
	
	if (self.providerName)
		return self.providerName;
	
	if (self.providerDisplayName)
		return self.providerDisplayName;
	
	return self.providerURL;

}

+ (NSSet *) keyPathsForValuesAffectingPrimaryImage {

	return [NSSet setWithObjects:
	
		@"imageOrder.@count",
		@"primaryImageURI",
	
	nil];

}

- (WAOpenGraphElementImage *) primaryImage {

	if (self.primaryImageURI)
		return (WAOpenGraphElementImage *)[self.managedObjectContext irManagedObjectForURI:self.primaryImageURI];
	
	if ([self.imageOrder count])
		return (WAOpenGraphElementImage *)[self.managedObjectContext irManagedObjectForURI:[self.imageOrder objectAtIndex:0]];
	
	return nil;

}

- (void) setPrimaryImage:(WAOpenGraphElementImage *)newPrimaryImage {

	if (newPrimaryImage == self.primaryImage)
		return;
	
	NSParameterAssert([self.images containsObject:newPrimaryImage]);
	self.primaryImageURI = [[newPrimaryImage objectID] URIRepresentation];

}

@end
