//
//  WAFile+LazyImages.m
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile+LazyImages.h"
#import "WAFile+WAConstants.h"
#import "WAFile+ImplicitBlobFulfillment.h"
#import "WAAssetsLibraryManager.h"

#import "UIKit+IRAdditions.h"
#import "WADataStore.h"
#import "NSString+WAAdditions.h"

static NSString * const kMemoryWarningObserver = @"-[WAFile(LazyImages) handleDidReceiveMemoryWarning:]";
static NSString * const kMemoryWarningObserverCreationDisabled = @"-[WAFile(LazyImages) isMemoryWarningObserverCreationDisabled]";

@implementation WAFile (LazyImages)

- (void) createMemoryWarningObserverIfAppropriate {
  
  id observer = objc_getAssociatedObject(self, &kMemoryWarningObserver);
  if (!observer && ![self isMemoryWarningObserverCreationDisabled]) {
    
    //	http://www.mikeash.com/pyblog/friday-qa-2011-09-30-automatic-reference-counting.html
    
    //	__weak refs are not good:
    //	NSManagedObject does
    //	override -retain.
    
    __unsafe_unretained WAFile *wSelf = self;
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
      
      [wSelf handleDidReceiveMemoryWarning:note];
      
    }];
    
    objc_setAssociatedObject(self, &kMemoryWarningObserver, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
  }
  
}

- (void) removeMemoryWarningObserverIfAppropriate {
  
  id observer = objc_getAssociatedObject(self, &kMemoryWarningObserver);
  
  if (observer) {
    
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    objc_setAssociatedObject(self, &kMemoryWarningObserver, nil, OBJC_ASSOCIATION_ASSIGN);
  }
  
}

- (void) disableMemoryWarningObserverCreation {
  
  objc_setAssociatedObject(self, &kMemoryWarningObserverCreationDisabled, (id)kCFBooleanTrue, OBJC_ASSOCIATION_ASSIGN);
  
}

- (BOOL) isMemoryWarningObserverCreationDisabled {
  
  return (objc_getAssociatedObject(self, &kMemoryWarningObserverCreationDisabled) == (id)kCFBooleanTrue);
  
}

- (void) handleDidReceiveMemoryWarning:(NSNotification *)aNotification {
  
  [self cleanImageCache];
  
}

+ (NSSet *) keyPathsForValuesAffectingBestPresentableImage {
  
  return [NSSet setWithObjects:
	kWAFileSmallThumbnailImage,
	kWAFileThumbnailImage,
	kWAFileLargeThumbnailImage,
	kWAFileResourceImage,
	nil];
  
}

- (UIImage *) bestPresentableImage {
  
  if (self.resourceImage)
    return self.resourceImage;
  
  if (self.largeThumbnailImage)
    return self.largeThumbnailImage;
  
  if (self.thumbnailImage)
    return self.thumbnailImage;
  
  if (self.smallThumbnailImage)
    return self.smallThumbnailImage;
  
  return nil;
  
}

+ (NSSet *) keyPathsForValuesAffectingSmallestPresentableImage {
  
  return [NSSet setWithObjects:
	kWAFileExtraSmallThumbnailImage,
	kWAFileSmallThumbnailImage,
	kWAFileThumbnailImage,
	kWAFileLargeThumbnailImage,
	nil];
  
}

- (UIImage *) smallestPresentableImage {
  
  if (self.extraSmallThumbnailImage)
    return self.extraSmallThumbnailImage;
  
  if (self.smallThumbnailImage)
    return self.smallThumbnailImage;
  
  if (self.thumbnailImage)
    return self.thumbnailImage;
  
  if (self.largeThumbnailImage)
    return self.largeThumbnailImage;
  
  return nil;
  
}

+ (NSSet *) keyPathsForValuesAffectingExtraSmallThumbnailImage {
  
  return [NSSet setWithObject:kWAFileExtraSmallThumbnailFilePath];
  
}

- (UIImage *) extraSmallThumbnailImage {
  
  [self createMemoryWarningObserverIfAppropriate];
  
  if (self.extraSmallThumbnailFilePath) {
    
    return [self imageAssociatedWithKey:&kWAFileExtraSmallThumbnailImage filePath:self.extraSmallThumbnailFilePath];
    
  } else {
    
    if (self.assetURL) {
      
      NSURL *ownURL = [[self objectID] URIRepresentation];
      
      [[WAAssetsLibraryManager defaultManager] assetForURL:[NSURL URLWithString:self.assetURL] resultBlock:^(ALAsset *asset) {
        
        NSManagedObjectContext *context = [[WADataStore defaultStore] autoUpdatingMOC];
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
        if (!file.extraSmallThumbnailFilePath) {
	UIImage *extraSmallThumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
	file.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(extraSmallThumbnailImage, 0.85f) extension:@"jpeg"] path];
	[context save:nil];
        }
        
      } failureBlock:^(NSError *error) {
        
        NSLog(@"Unable to read asset: %s %@", __PRETTY_FUNCTION__, error);
        
      }];
      
    } else {
      
      // trigger downloading if small thumbnail does not exist
      [self setDisplayingSmallThumbnail:YES];
      
      if (self.smallThumbnailFilePath) {
        
        NSURL *ownURL = [[self objectID] URIRepresentation];

        [self.smallThumbnailFilePath makeThumbnailWithOptions:WAThumbnailTypeExtraSmall completeBlock:^(UIImage *image) {

	NSManagedObjectContext *context = [[WADataStore defaultStore] autoUpdatingMOC];
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
	if (!file.extraSmallThumbnailFilePath) {
	  file.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(image, 0.85f) extension:@"jpeg"] path];
	  [context save:nil];
	}

        }];
        
      }
      
    }
    
    return nil;
  }
  
}

- (void)setExtraSmallThumbnailImage:(UIImage *)extraSmallThumbnailImage {
  
  [self irAssociateObject:extraSmallThumbnailImage usingKey:&kWAFileExtraSmallThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileExtraSmallThumbnailImage];
  
}

+ (NSSet *) keyPathsForValuesAffectingResourceImage {
  
  return [NSSet setWithObject:kWAFileResourceFilePath];
  
}

- (UIImage *) resourceImage {
  
  [self createMemoryWarningObserverIfAppropriate];
  
  UIImage *image = [self imageAssociatedWithKey:&kWAFileResourceImage filePath:self.resourceFilePath];
  
  if (!image) {
    if (self.assetURL) {
      __weak WAFile *wSelf = self;
      [[WAAssetsLibraryManager defaultManager] assetForURL:[NSURL URLWithString:self.assetURL] resultBlock:^(ALAsset *asset) {
        
        if (asset && ![wSelf imageAssociatedWithKey:&kWAFileResourceImage filePath:nil]) {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	  UIImage *assetImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]];
	  [wSelf setResourceImage:assetImage];
	});
        }
        
      } failureBlock:^(NSError *error) {
        
        NSLog(@"Unable to read asset: %s %@", __PRETTY_FUNCTION__, error);
        
      }];
    }
  }
  
  return image;
}

- (void) setResourceImage:(UIImage *)resourceImage {
  
  [self irAssociateObject:resourceImage usingKey:&kWAFileResourceImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileResourceImage];
  
}

+ (NSSet *) keyPathsForValuesAffectingLargeThumbnailImage {
  
  return [NSSet setWithObject:kWAFileLargeThumbnailFilePath];
  
}

- (UIImage *) largeThumbnailImage {
  
  [self createMemoryWarningObserverIfAppropriate];
  
  return [self imageAssociatedWithKey:&kWAFileLargeThumbnailImage filePath:self.largeThumbnailFilePath];
  
}

- (void) setLargeThumbnailImage:(UIImage *)largeThumbnailImage {
  
  [self irAssociateObject:largeThumbnailImage usingKey:&kWAFileLargeThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileLargeThumbnailImage];
  
}

+ (NSSet *) keyPathsForValuesAffectingThumbnailImage {
  
  return [NSSet setWithObject:kWAFileThumbnailFilePath];
  
}

- (UIImage *) thumbnailImage {
  
  [self createMemoryWarningObserverIfAppropriate];
  
  [self setDisplayingThumbnail:YES];
  
  return [self imageAssociatedWithKey:&kWAFileThumbnailImage filePath:self.thumbnailFilePath];
  
}

- (void) setThumbnailImage:(UIImage *)thumbnailImage {
  
  [self irAssociateObject:thumbnailImage usingKey:&kWAFileThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileThumbnailImage];
  
}

+ (NSSet *) keyPathsForValuesAffectingSmallThumbnailImage {
  
  return [NSSet setWithObject:kWAFileSmallThumbnailFilePath];
  
}

- (UIImage *) smallThumbnailImage {
  
  [self createMemoryWarningObserverIfAppropriate];
  
  [self setDisplayingSmallThumbnail:YES];
  
  UIImage *image = [self imageAssociatedWithKey:&kWAFileSmallThumbnailImage filePath:self.smallThumbnailFilePath];
  if (!image) {
    // if no small thumbnail, load asset thumbnail first for UI responsiveness
    image = self.extraSmallThumbnailImage;
  }
  
  return image;
}

- (void) setSmallThumbnailImage:(UIImage *)smallThumbnailImage {
  
  [self irAssociateObject:smallThumbnailImage usingKey:&kWAFileSmallThumbnailImage policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:kWAFileSmallThumbnailImage];
  
}

- (UIImage *) imageAssociatedWithKey:(const void *)key filePath:(NSString *)filePath {
  
  UIImage *image = objc_getAssociatedObject(self, key);
  if (image)
    return image;
  
  if (!filePath)
    return nil;
  
  image = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil]];
  image.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
  
  [self irAssociateObject:image usingKey:key policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];
  
  return image;
  
}

- (UIImage *) thumbnail {
  
  UIImage *primitiveThumbnail = [self primitiveValueForKey:@"thumbnail"];
  
  if (primitiveThumbnail)
    return primitiveThumbnail;
  
  if (!self.resourceImage)
    return nil;
  
  primitiveThumbnail = [[self.resourceImage irStandardImage] irScaledImageWithSize:IRCGSizeGetCenteredInRect(self.resourceImage.size, (CGRect){ CGPointZero, (CGSize){ 512, 512 } }, 0.0f, YES).size];
  [self setPrimitiveValue:primitiveThumbnail forKey:@"thumbnail"];
  
  return self.thumbnail;
  
}

- (void) cleanImageCache {
  
  [self irAssociateObject:nil usingKey:&kWAFileExtraSmallThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
  [self irAssociateObject:nil usingKey:&kWAFileSmallThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
  [self irAssociateObject:nil usingKey:&kWAFileThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
  [self irAssociateObject:nil usingKey:&kWAFileLargeThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
  [self irAssociateObject:nil usingKey:&kWAFileResourceImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
  
}

@end
