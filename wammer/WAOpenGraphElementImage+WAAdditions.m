//
//  WAOpenGraphElementImage+WAAdditions.m
//  wammer
//
//  Created by Evadne Wu on 2/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAOpenGraphElementImage+WAAdditions.h"

#import <UIKit/UIKit.h>

#import "WADataStore.h"
#import "IRRemoteResourcesManager.h"
#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"
#import "IRManagedObject+WAFileHandling.h"

NSString * kWAOpenGraphElementImageFilePath = @"imageFilePath";
NSString * kWAOpenGraphElementImageRemoteURL = @"imageRemoteURL";
NSString * kWAOpenGraphElementImageImage = @"image";


@interface WAOpenGraphElementImage (CoreDataGeneratedPrimitiveAccessors)

- (void) setPrimitiveImageFilePath:(NSString *)newImageFilePath;
- (NSString *) primitiveImageFilePath;

@end


@implementation WAOpenGraphElementImage (WAAdditions)

- (void) setImageFilePath:(NSString *)newImageFilePath {

	[self willChangeValueForKey:@"imageFilePath"];
	[self setPrimitiveImageFilePath:[self relativePathFromPath:newImageFilePath]];
	[self didChangeValueForKey:@"imageFilePath"];
		
	[self setImage:nil];

}

- (NSString *) imageFilePath {

	NSString *primitivePath = [self primitiveValueForKey:kWAOpenGraphElementImageFilePath];
	
	if (primitivePath)
		return [self absolutePathFromPath:primitivePath];
		
	if (!self.imageRemoteURL)
		return nil;
	
	NSURL *imageURL = [NSURL URLWithString:self.imageRemoteURL];
	if (!imageURL)
		imageURL = [NSURL URLWithString:[self.imageRemoteURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	if (imageURL && ![imageURL isFileURL]) {

		NSURL *ownURL = [[self objectID] URIRepresentation];
		
		[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:imageURL withCompletionBlock:^(NSURL *tempFileURLOrNil) {
		
			if (!tempFileURLOrNil)
				return;
				
			WAOpenGraphElementImage *updatedObject = (WAOpenGraphElementImage *)[[WADataStore defaultStore] updateObjectAtURI:ownURL inContext:nil takingBlobFromTemporaryFile:[tempFileURLOrNil path] usingResourceType:nil forKeyPath:@"imageFilePath" matchingURL:imageURL forKeyPath:@"imageRemoteURL"];
			
			if (updatedObject) {
			
				NSError *savingError = nil;
				if (![updatedObject.managedObjectContext save:&savingError])
					NSLog(@"Error saving: %@", savingError);
				
			}
			
		}];
		
		return nil;

	}
	
	primitivePath = [imageURL path];
	
	if (imageURL && primitivePath) {
		[self willChangeValueForKey:kWAOpenGraphElementImageFilePath];
		[self setPrimitiveValue:primitivePath forKey:kWAOpenGraphElementImageFilePath];
		[self didChangeValueForKey:kWAOpenGraphElementImageFilePath];
	}
	
	return primitivePath;

}

+ (NSSet *) keyPathsForValuesAffectingImage {

	return [NSSet setWithObjects:
	
		@"imageFilePath",
		@"imageRemoteURL",
				
	nil];

}

- (UIImage *) image {

	UIImage *image = objc_getAssociatedObject(self, &kWAOpenGraphElementImageImage);
	if (image)
		return image;
	
	NSString *imageFilePath = self.imageFilePath;
	if (!imageFilePath)
		return nil;
	
	image = [UIImage imageWithData:[NSData dataWithContentsOfMappedFile:imageFilePath]];
	image.irRepresentedObject = [NSValue valueWithNonretainedObject:self];

	[self irAssociateObject:image usingKey:&kWAOpenGraphElementImageImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];
	
	return image;
	
}

- (void) setImage:(UIImage *)newImage {

	[self irAssociateObject:newImage usingKey:&kWAOpenGraphElementImageImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAOpenGraphElementImageImage];

}

@end
