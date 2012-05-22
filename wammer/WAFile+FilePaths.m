//
//  WAFile+FilePaths.m
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile+WAConstants.h"
#import "WAFile+CoreDataGeneratedPrimitiveAccessors.h"
#import "WAFile+FilePaths.h"
#import "WAFile+ImplicitBlobFulfillment.h"

#import "WADataStore.h"

#import "IRManagedObject+WAFileHandling.h"


@implementation WAFile (FilePaths)

- (NSString *) filePathForKey:(NSString *)filePathKey usingFileURLStringKey:(NSString *)urlStringKey {

	[self willAccessValueForKey:filePathKey];
	NSString *primitivePath = [self primitiveValueForKey:filePathKey];
	[self didAccessValueForKey:filePathKey];
	
	if (primitivePath)
		return [self absolutePathFromPath:primitivePath];
	
	[self willAccessValueForKey:urlStringKey];
	NSString *urlString = [self primitiveValueForKey:urlStringKey];
	[self didAccessValueForKey:urlStringKey];
	
	if (!urlString)
		return nil;
	
	NSURL *fileURL = [NSURL URLWithString:urlString];
	if (!fileURL)
		return nil;

	if ([fileURL isFileURL])
		return [fileURL path];
	
	[self retrieveBlobWithURLStringKey:urlStringKey filePathKey:filePathKey];
	
	return nil;	

}

- (void) setFilePath:(NSString *)newAbsoluteFilePath forKey:(NSString *)filePathKey replacingImageKey:(NSString *)imageKey {
	
	[self willChangeValueForKey:filePathKey];
	
	[self setPrimitiveValue:[self relativePathFromPath:newAbsoluteFilePath] forKey:filePathKey];
	[self irAssociateObject:nil usingKey:&imageKey policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:imageKey];
	
	[self didChangeValueForKey:filePathKey];

}

+ (NSSet *) keyPathsForValuesAffectingResourceFilePath {

	return [NSSet setWithObject:kWAFileResourceURL];

}

- (NSString *) resourceFilePath {

	return [self filePathForKey:kWAFileResourceFilePath usingFileURLStringKey:kWAFileResourceURL];

}

- (void) setResourceFilePath:(NSString *)newResourceFilePath {

	[self setFilePath:newResourceFilePath forKey:kWAFileResourceFilePath replacingImageKey:kWAFileResourceImage];
	
}

+ (NSSet *) keyPathsForValuesAffectingSmallThumbnailFilePath {

	return [NSSet setWithObject:kWAFileSmallThumbnailURL];

}

- (NSString *) smallThumbnailFilePath {

	return [self filePathForKey:kWAFileSmallThumbnailFilePath usingFileURLStringKey:kWAFileSmallThumbnailURL];

}

- (void) setSmallThumbnailFilePath:(NSString *)newSmallThumbnailFilePath {
	
	[self setFilePath:newSmallThumbnailFilePath forKey:kWAFileSmallThumbnailFilePath replacingImageKey:kWAFileSmallThumbnailImage];
	
}

+ (NSSet *) keyPathsForValuesAffectingThumbnailFilePath {

	return [NSSet setWithObject:kWAFileThumbnailURL];

}

- (NSString *) thumbnailFilePath {

	return [self filePathForKey:kWAFileThumbnailFilePath usingFileURLStringKey:kWAFileThumbnailURL];

}

- (void) setThumbnailFilePath:(NSString *)newThumbnailFilePath {
	
	[self setFilePath:newThumbnailFilePath forKey:kWAFileThumbnailFilePath replacingImageKey:kWAFileThumbnailImage];
	
}

+ (NSSet *) keyPathsForValuesAffectingLargeThumbnailFilePath {

	return [NSSet setWithObject:kWAFileLargeThumbnailURL];

}

- (NSString *) largeThumbnailFilePath {

	return [self filePathForKey:kWAFileLargeThumbnailFilePath usingFileURLStringKey:kWAFileLargeThumbnailURL];

}

- (void) setLargeThumbnailFilePath:(NSString *)newLargeThumbnailFilePath {
	
	[self setFilePath:newLargeThumbnailFilePath forKey:kWAFileLargeThumbnailFilePath replacingImageKey:kWAFileLargeThumbnailImage];
	
}

@end
