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

		NSURL *ownURL = [[self objectID] URIRepresentation];
		[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:thumbnailURL withCompletionBlock:^(NSURL *tempFileURLOrNil) {

			if (!tempFileURLOrNil)
				return;

			WAFilePageElement *updatedObject = (WAFilePageElement *)[[WADataStore defaultStore] updateObjectAtURI:ownURL inContext:nil takingBlobFromTemporaryFile:[tempFileURLOrNil path] usingResourceType:nil forKeyPath:kWAFilePageElementThumbnailFilePath matchingURL:thumbnailURL forKeyPath:kWAFilePageElementThumbnailFilePath];

			if ([updatedObject hasChanges]) {

				NSError *savingError = nil;
				if (![updatedObject.managedObjectContext save:&savingError])
					NSLog(@"Error saving: %@", savingError);

			}

		}];

	}

	return nil;

}

- (void)setThumbnailFilePath:(NSString *)thumbnailFilePath {

	NSString *filePath = [self relativePathFromPath:thumbnailFilePath];
	[self setPrimitiveValue:filePath forKey:kWAFilePageElementThumbnailFilePath];
	WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
	[cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation] filePath:filePath filePathKey:kWAFilePageElementThumbnailFilePath];

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

	[self createMemoryWarningObserverIfAppropriate];

	image = [UIImage imageWithData:[NSData dataWithContentsOfFile:thumbnailFilePath options:NSDataReadingMappedIfSafe error:nil]];
	
	[self irAssociateObject:image usingKey:&kWAFilePageElementThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];

	return image;

}

- (void)setThumbnailImage:(UIImage *)newImage {

	[self irAssociateObject:newImage usingKey:&kWAFilePageElementThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFilePageElementThumbnailImage];

}

- (void)createMemoryWarningObserverIfAppropriate {

	__weak WAFilePageElement *wSelf = self;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[[NSNotificationCenter defaultCenter] addObserver:wSelf selector:@selector(handleDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	});

}

- (void)dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

#pragma mark - Target actions

- (void)handleDidReceiveMemoryWarning:(NSNotification *)notification {

	[self irAssociateObject:nil usingKey:&kWAFilePageElementThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];

}

@end
