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
#import "WADefines.h"
#import "WAAppDelegate_iOS.h"
#import "WACacheManager.h"
#import "WARemoteInterface.h"


@implementation WAFile (FilePaths)

- (NSString *) filePathForKey:(NSString *)filePathKey usingFileURLStringKey:(NSString *)urlStringKey {
  
  [self willAccessValueForKey:filePathKey];
  NSString *primitivePath = [self primitiveValueForKey:filePathKey];
  [self didAccessValueForKey:filePathKey];
  
  NSString *filePath = [self absolutePathFromPath:primitivePath];
  if (primitivePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
    [cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation] filePath:filePath filePathKey:filePathKey];
    return filePath;
  }
  
  [self willAccessValueForKey:urlStringKey];
  NSString *urlString = [self primitiveValueForKey:urlStringKey];
  [self didAccessValueForKey:urlStringKey];
  
  if (!urlString) {
    if (urlStringKey == kWAFileSmallThumbnailURL) {
      urlString = [NSString stringWithFormat:@"http://invalid.local/v3/attachments/view?object_id=%@&image_meta=%@", self.identifier, @"small"];
    } else if (urlStringKey == kWAFileThumbnailURL) {
      urlString = [NSString stringWithFormat:@"http://invalid.local/v3/attachments/view?object_id=%@&image_meta=%@", self.identifier, @"medium"];
    }
  }
  
  if (!urlString) {
    return nil;
  }
  
  NSURL *fileURL = [NSURL URLWithString:urlString];
  if (!fileURL)
    return nil;
  
  if ([fileURL isFileURL])
    return [fileURL path];
  
  if ([self displayingSmallThumbnail] || [self displayingThumbnail]) {
    [self retrieveBlobWithURLString:urlString URLStringKey:urlStringKey filePathKey:filePathKey];
  }
  
  return nil;
  
}

- (void) setFilePath:(NSString *)newAbsoluteFilePath forKey:(NSString *)filePathKey replacingImageKey:(NSString *)imageKey {
  
  [self willChangeValueForKey:filePathKey];
  
  NSString *filePath = [self relativePathFromPath:newAbsoluteFilePath];
  [self setPrimitiveValue:filePath forKey:filePathKey];
  [self irAssociateObject:nil usingKey:&imageKey policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:imageKey];
  WACacheManager *cacheManager = [(WAAppDelegate_iOS *)AppDelegate() cacheManager];
  [cacheManager insertOrUpdateCacheWithRelationship:[[self objectID] URIRepresentation] filePath:[self absolutePathFromPath:filePath] filePathKey:filePathKey];
  
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
