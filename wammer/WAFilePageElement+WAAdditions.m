//
//  WAFilePageElement+WAAdditions.m
//  wammer
//
//  Created by kchiu on 12/12/5.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFilePageElement+WAAdditions.h"
#import "IRManagedObject+WAFileHandling.h"
#import "WACacheManager.h"
#import "WAAppDelegate_iOS.h"
#import "WADefines.h"
#import "IRRemoteResourcesManager.h"
#import "WADataStore.h"

static NSString * const kWAFilePageElementThumbnailFilePath = @"thumbnailFilePath";
static NSString * const kWAFilePageElementThumbnailURL = @"thumbnailURL";
static NSString * const kWAFilePageElementThumbnailImage = @"thumbnailImage";

@implementation WAFilePageElement (WAAdditions)
@dynamic thumbnailImage;

- (NSString *)thumbnailFilePath {

	NSString *primitivePath = [self primitiveValueForKey:kWAFilePageElementThumbnailFilePath];
	NSString *filePath = [self absolutePathFromPath:primitivePath];
	
	if (primitivePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
		[cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation] filePath:filePath filePathKey:kWAFilePageElementThumbnailFilePath];
		return filePath;
	}

	if (!self.thumbnailURL) {
		return nil;
	}

	NSURL *thumbnailURL = [NSURL URLWithString:self.thumbnailURL];
	if (thumbnailURL && ![thumbnailURL isFileURL]) {

		__weak WAFilePageElement *wSelf = self;
		NSURL *ownURL = [[self objectID] URIRepresentation];
		[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:thumbnailURL withCompletionBlock:^(NSURL *tempFileURLOrNil) {

			if (!tempFileURLOrNil)
				return;

			if (![UIImage imageWithContentsOfFile:[tempFileURLOrNil path]]) {
				int64_t delayInSeconds = 3.0;
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
				dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
					[wSelf thumbnailFilePath];
				});
				return;
			}

			[[[wSelf class] sharedResourceHandlingQueue] addOperationWithBlock:^{

				WADataStore *ds = [WADataStore defaultStore];
				NSManagedObjectContext *context = [ds autoUpdatingMOC];
				context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;

				WAFilePageElement *updatedObject = (WAFilePageElement *)[ds updateObjectAtURI:ownURL inContext:context takingBlobFromTemporaryFile:[tempFileURLOrNil path] usingResourceType:nil forKeyPath:kWAFilePageElementThumbnailFilePath matchingURL:thumbnailURL forKeyPath:kWAFilePageElementThumbnailURL];
				
				if ([updatedObject hasChanges]) {

					NSError *savingError = nil;
					if (![updatedObject.managedObjectContext save:&savingError])
						NSLog(@"Error saving: %@", savingError);
					
				}

			}];

		}];

	}

	return nil;

}

- (void)setThumbnailFilePath:(NSString *)thumbnailFilePath {

	[self willChangeValueForKey:kWAFilePageElementThumbnailFilePath];

	NSString *filePath = [self relativePathFromPath:thumbnailFilePath];
	[self setPrimitiveValue:filePath forKey:kWAFilePageElementThumbnailFilePath];
	WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
	[cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation] filePath:thumbnailFilePath filePathKey:kWAFilePageElementThumbnailFilePath];

	[self didChangeValueForKey:kWAFilePageElementThumbnailFilePath];

}

+ (NSSet *)keyPathsForValuesAffectingThumbnailImage {

	return [NSSet setWithObjects:

					@"thumbnailFilePath",
					@"thumbnailURL",

					nil];

}

- (UIImage *)thumbnailImage {

	UIImage *image = objc_getAssociatedObject(self, &kWAFilePageElementThumbnailImage);
	if (image)
		return image;

	NSString *thumbnailFilePath = self.thumbnailFilePath;
	if (!thumbnailFilePath)
		return nil;

	image = [UIImage imageWithData:[NSData dataWithContentsOfFile:thumbnailFilePath options:NSDataReadingMappedIfSafe error:nil]];
	
	[self irAssociateObject:image usingKey:&kWAFilePageElementThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];

	return image;

}

- (void)setThumbnailImage:(UIImage *)newImage {

	[self irAssociateObject:newImage usingKey:&kWAFilePageElementThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFilePageElementThumbnailImage];

}

+ (NSOperationQueue *)sharedResourceHandlingQueue {

	static NSOperationQueue *queue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1];
	});

	return queue;

}

@end
