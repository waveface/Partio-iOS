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
#import "NSString+WAAdditions.h"

static NSString * const kWAFilePageElementThumbnailFilePath = @"thumbnailFilePath";
static NSString * const kWAFilePageElementThumbnailURL = @"thumbnailURL";
static NSString * const kWAFilePageElementThumbnailImage = @"thumbnailImage";
static NSString * const kWAFilePageElementExtraSmallThumbnailFilePath = @"extraSmallThumbnailFilePath";
static NSString * const kWAFilePageElementExtraSmallThumbnailImage = @"extraSmallThumbnailImage";

@implementation WAFilePageElement (WAAdditions)
@dynamic thumbnailImage;
@dynamic extraSmallThumbnailImage;

- (NSString *)thumbnailFilePath {
  
  NSString *primitivePath = [self primitiveValueForKey:kWAFilePageElementThumbnailFilePath];
  
  if (primitivePath && [[NSFileManager defaultManager] fileExistsAtPath:primitivePath]) {
    WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
    [cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation]
				     filePath:primitivePath
				  filePathKey:kWAFilePageElementThumbnailFilePath];
    return primitivePath;
  }
  
  if (!self.thumbnailURL) {
    return nil;
  }
  
  NSURL *thumbnailURL = [NSURL URLWithString:self.thumbnailURL];
  if (thumbnailURL && ![thumbnailURL isFileURL]) {
    
    Class class = [self class];
    
    NSURL *ownURL = [[self objectID] URIRepresentation];
    [[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:thumbnailURL withCompletionBlock:^(NSURL *tempFileURLOrNil) {
      
      if (!tempFileURLOrNil)
        return;
      
      if (!class) {
        return;
      }
      
      NSString *filePath = [tempFileURLOrNil path];
      if (![UIImage imageWithContentsOfFile:filePath]) {
        int64_t delayInSeconds = 3.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
	NSManagedObjectContext *context = [[WADataStore defaultStore] autoUpdatingMOC];
	WAFilePageElement *page = (WAFilePageElement *)[context irManagedObjectForURI:ownURL];
	[page thumbnailFilePath];
        });
        return;
      }
      
      [filePath makeThumbnailWithOptions:WAThumbnailTypeExtraSmall completeBlock:^(UIImage *image) {

        NSManagedObjectContext *context = [[WADataStore defaultStore] autoUpdatingMOC];
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        WAFilePageElement *page = (WAFilePageElement *)[context irManagedObjectForURI:ownURL];
        if (!page.extraSmallThumbnailFilePath) {
	page.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(image, 0.85f) extension:@"jpeg"] path];
	[context save:nil];
        }

      }];
      
      [[class sharedResourceHandlingQueue] addOperationWithBlock:^{
        
        WADataStore *ds = [WADataStore defaultStore];
        NSManagedObjectContext *context = [ds autoUpdatingMOC];
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        WAFilePageElement *updatedObject =
        (WAFilePageElement *)[ds updateObjectAtURI:ownURL
				 inContext:context
		   takingBlobFromTemporaryFile:[tempFileURLOrNil path]
			   usingResourceType:nil
				forKeyPath:kWAFilePageElementThumbnailFilePath
			         matchingURL:thumbnailURL
				forKeyPath:kWAFilePageElementThumbnailURL];
        
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
  
  [self setPrimitiveValue:thumbnailFilePath forKey:kWAFilePageElementThumbnailFilePath];
  WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
  [cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation]
				   filePath:thumbnailFilePath
				filePathKey:kWAFilePageElementThumbnailFilePath];
  
  [self didChangeValueForKey:kWAFilePageElementThumbnailFilePath];
  
}

+ (NSSet *)keyPathsForValuesAffectingThumbnailImage {
  
  return [NSSet setWithObjects:
	
	@"thumbnailFilePath",
	@"thumbnailURL",
	
	nil];
  
}

- (UIImage *)thumbnailImage {
  
  return [self imageAssociateWithKey:&kWAFilePageElementThumbnailImage filePath:self.thumbnailFilePath];
  
}

- (NSString *)extraSmallThumbnailFilePath {
  
  NSString *primitivePath = [self primitiveValueForKey:kWAFilePageElementExtraSmallThumbnailFilePath];
  
  if (primitivePath && [[NSFileManager defaultManager] fileExistsAtPath:primitivePath]) {
    WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
    [cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation]
				     filePath:primitivePath
				  filePathKey:kWAFilePageElementExtraSmallThumbnailFilePath];
    return primitivePath;
  }
  
  return nil;
  
}

- (void)setExtraSmallThumbnailFilePath:(NSString *)extraSmallThumbnailFilePath {
  
  [self willChangeValueForKey:kWAFilePageElementExtraSmallThumbnailFilePath];
  
  [self setPrimitiveValue:extraSmallThumbnailFilePath forKey:kWAFilePageElementExtraSmallThumbnailFilePath];
  WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
  [cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation]
				   filePath:extraSmallThumbnailFilePath
				filePathKey:kWAFilePageElementExtraSmallThumbnailFilePath];
  
  [self didChangeValueForKey:kWAFilePageElementExtraSmallThumbnailFilePath];
  
}


+ (NSSet *) keyPathsForValuesAffectingExtraSmallThumbnailImage {
  
  return [NSSet setWithObject:kWAFilePageElementExtraSmallThumbnailFilePath];
  
}

- (UIImage *)extraSmallThumbnailImage {
  
  return [self imageAssociateWithKey:&kWAFilePageElementExtraSmallThumbnailImage
		        filePath:self.extraSmallThumbnailFilePath];
  
}

- (UIImage *)imageAssociateWithKey:(const void *)key filePath:(NSString *)filePath {
  
  UIImage *image = objc_getAssociatedObject(self, key);
  if (image)
    return image;
  
  if (!filePath)
    return nil;
  
  image = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath
					      options:NSDataReadingMappedIfSafe
					        error:nil]];
  
  [self irAssociateObject:image usingKey:key policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];
  
  return image;
  
}

- (void)cleanImageCache {
  
  [self irAssociateObject:nil
	       usingKey:&kWAFilePageElementThumbnailImage
	         policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
  
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
