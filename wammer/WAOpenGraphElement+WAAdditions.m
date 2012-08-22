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


@implementation WAOpenGraphElement (WAAdditions)

+ (BOOL) skipsNonexistantRemoteKey {

	return YES;
	
}

+ (NSSet *) keyPathsForValuesAffectingRepresentingImage {

	return [NSSet setWithObject:@"images"];

}

- (WAOpenGraphElementImage *) representingImage {

	[self willAccessValueForKey:@"representingImage"];
	WAOpenGraphElementImage *image = [self primitiveValueForKey:@"representingImage"];
	[self didAccessValueForKey:@"representingImage"];
	
// avoid displaying preview thumbnails if thumbnail_url is empty
//	if (!image) {
//	
//		[self willAccessValueForKey:@"images"];
//		NSOrderedSet *images = [self primitiveValueForKey:@"images"];
//		
//		if ([images count]) {
//			image = [[images array] objectAtIndex:0];
//		}
//
//		[self didAccessValueForKey:@"images"];
//	
//	}
	
	return image;

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

@end
