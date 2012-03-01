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

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *)key {

	if ([super automaticallyNotifiesObserversForKey:key])
		return YES;
	
	if ([key isEqualToString:@"images"])
		return YES;
	
	return NO;

}

+ (NSSet *) keyPathsForValuesAffectingImages {

	return [NSSet setWithObjects:@"imageOrder", nil];

}

+ (NSSet *) keyPathsForValuesAffectingImageOrder {

	return [NSSet setWithObjects:@"images", nil];

}

- (void) irAwake {

	[super irAwake];
	[self irReconcileObjectOrderWithKey:@"images" usingArrayKeyed:@"imageOrder"];
	
}

- (NSArray *) imageOrder {

	return [self irBackingOrderArrayKeyed:@"imageOrder"];

}

- (void) didChangeValueForKey:(NSString *)inKey withSetMutation:(NSKeyValueSetMutationKind)inMutationKind usingObjects:(NSSet *)inObjects {

	if ([inKey isEqualToString:@"images"]) {
    
    [self irUpdateObjects:inObjects withRelationshipKey:@"images" usingOrderArray:@"imageOrder" withSetMutation:inMutationKind];
		return;
    
  }

	[super didChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
	
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
