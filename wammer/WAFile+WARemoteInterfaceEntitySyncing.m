//
//  WAFile+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IRAsyncOperation.h"

#import "WAFile+WARemoteInterfaceEntitySyncing.h"
#import "WADataStore.h"
#import "WARemoteInterface.h"
#import "WADefines.h"

#import "UIImage+WAAdditions.h"
#import "ALAssetRepresentation+IRAdditions.h"
#import "WAAssetsLibraryManager.h"

#import "NSDate+WAAdditions.h"

#import "SSToolkit/NSDate+SSToolkitAdditions.h"
#import "ALAsset+WAAdditions.h"
#import "NSDate+WAAdditions.h"
#import <NSString+SSToolkitAdditions.h>


NSString * kWAFileEntitySyncingErrorDomain = @"com.waveface.wammer.file.entitySyncing";
NSError * WAFileEntitySyncingError (WAFileSyncingErrorCode code, NSString *descriptionKey, NSString *reasonKey) {
  return [NSError irErrorWithDomain:kWAFileEntitySyncingErrorDomain code:code descriptionLocalizationKey:descriptionKey reasonLocalizationKey:reasonKey userInfo:nil];
}

NSString * const kWAFileSyncStrategy = @"WAFileSyncStrategy";
NSString * const kWAFileSyncDefaultStrategy = @"WAFileSyncDefaultStrategy";
NSString * const kWAFileSyncAdaptiveQualityStrategy = @"WAFileSyncAdaptiveQualityStrategy";
NSString * const kWAFileSyncReducedQualityStrategy = @"WAFileSyncReducedQualityStrategy";
NSString * const kWAFileSyncFullQualityStrategy = @"WAFileSyncFullQualityStrategy";


@implementation WAFile (WARemoteInterfaceEntitySyncing)

- (void) configureWithRemoteDictionary:(NSDictionary *)inDictionary {
  
  NSMutableDictionary *usedDictionary = [inDictionary mutableCopy];
  
  if ([usedDictionary[@"url"] isEqualToString:@""])
    [usedDictionary removeObjectForKey:@"url"];
  
  [super configureWithRemoteDictionary:usedDictionary];
  
  if (!self.resourceType) {
    
    NSString *pathExtension = [self.remoteFileName pathExtension];
    if (pathExtension) {
      
      CFStringRef preferredUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, NULL);
      self.resourceType = (__bridge_transfer NSString *)preferredUTI;
      
    }
    
  }
  
}

+ (NSString *) keyPathHoldingUniqueValue {
  
  return @"identifier";
  
}

+ (BOOL) skipsNonexistantRemoteKey {
  
  //	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
  //	that -configureWithRemoteDictionary: gets
  return YES;
  
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
  
  static NSDictionary *mapping = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    mapping = @{
    @"code_name": @"codeName",
    
    @"description": @"text",
    @"device_id": @"creationDeviceIdentifier",
    @"file_name": @"remoteFileName",
    @"file_size": @"remoteFileSize",
    @"event_time": @"created",
    @"photoDay": @"photoDay",
    @"outdated": @"outdated",
    @"hidden": @"hidden",
    
    @"image": @"remoteRepresentedImage",
    @"md5": @"remoteResourceHash",
    @"mime_type": @"resourceType",
    @"object_id": @"identifier",
    @"title": @"title",
    @"type": @"remoteResourceType",
    
    @"small_thumbnail_url": @"smallThumbnailURL",
    @"thumbnail_url": @"thumbnailURL",
    @"large_thumbnail_url": @"largeThumbnailURL",
    
    @"url": @"resourceURL",
    @"file_create_time": @"timestamp",
    
    @"pageElements": @"pageElements",
    @"accessLogs": @"accessLogs",
    
    @"web_url": @"webURL",
    @"web_title": @"webTitle",
    @"web_favicon": @"webFaviconURL"};
    
  });
  
  return mapping;
  
}

+ (NSDictionary *) defaultHierarchicalEntityMapping {
  
  return @{
  @"photoDay": @"WAPhotoDay",
  @"accessLogs": @"WAFileAccessLog",
  @"pageElements": @"WAFilePageElement"
  };
  
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {
  
  NSMutableDictionary *returnedDictionary = [incomingRepresentation mutableCopy];
  
  NSString *smallImageRepURLString = [returnedDictionary valueForKeyPath:@"image_meta.small.url"];
  if ([smallImageRepURLString isKindOfClass:[NSString class]])
    returnedDictionary[@"small_thumbnail_url"] = smallImageRepURLString;
  
  NSString *mediumImageRepURLString = [returnedDictionary valueForKeyPath:@"image_meta.medium.url"];
  if ([mediumImageRepURLString isKindOfClass:[NSString class]])
    returnedDictionary[@"thumbnail_url"] = mediumImageRepURLString;
  
  NSString *largeImageRepURLString = [returnedDictionary valueForKeyPath:@"image_meta.large.url"];
  if ([largeImageRepURLString isKindOfClass:[NSString class]])
    returnedDictionary[@"large_thumbnail_url"] = largeImageRepURLString;
  
  NSString *incomingFileType = incomingRepresentation[@"type"];
  if ([incomingFileType isEqualToString:@"image"]) {
    
    NSString *eventDateTime = incomingRepresentation[@"event_time"];
    if (eventDateTime) {
      NSDate *day = [[NSDate dateFromISO8601String:eventDateTime] dayBegin];
      if (day) {
        [returnedDictionary setObject: @{@"day": day}
			 forKey:@"photoDay"];
      } else {
        NSLog(@"Unable to convert event time on attachment: %@", incomingRepresentation);
      }
    }
    
    
  } else if ([incomingFileType isEqualToString:@"webthumb"]) {
    
    if (incomingRepresentation[@"web_meta"]) {
      
      NSString *resourceURLString = [returnedDictionary valueForKeyPath:@"url"];
      if ([resourceURLString isKindOfClass:[NSString class]])
        returnedDictionary[@"thumbnail_url"] = [NSString stringWithFormat:@"%@&image_meta=medium", resourceURLString];
      
      NSString *webURLString = [incomingRepresentation valueForKeyPath:@"web_meta.url"];
      if ([webURLString isKindOfClass:[NSString class]])
        returnedDictionary[@"web_url"] = webURLString;
      
      NSString *webFaviconURLString = [incomingRepresentation valueForKeyPath:@"web_meta.favicon"];
      if ([webFaviconURLString isKindOfClass:[NSString class]])
        returnedDictionary[@"web_favicon"] = webFaviconURLString;
      
      NSString *webTitleString = [incomingRepresentation valueForKeyPath:@"web_meta.title"];
      if ([webTitleString isKindOfClass:[NSString class]])
        returnedDictionary[@"web_title"] = webTitleString;
      
      NSMutableArray *accessLogArray = [NSMutableArray array];
      for (NSDictionary *access in [incomingRepresentation valueForKeyPath:@"web_meta.accesses"]) {
        NSString *identifier = [access[@"time"] stringByAppendingString:[incomingRepresentation valueForKeyPath:@"object_id"]];
        NSString *hashedIdentifier = [identifier MD5Sum];
        NSDate *date = [NSDate dateFromISO8601String:access[@"time"]];
        NSString *source = access[@"from"];
        NSDictionary *accessLog = @{
        @"identifier": hashedIdentifier,
        @"accessTime": date,
        @"accessSource": source,
        @"dayWebpages": @{@"day": [date dayBegin]}
        };
        [accessLogArray addObject:accessLog];
      }
      if (accessLogArray.count)
        returnedDictionary[@"accessLogs"] = accessLogArray;
	  
	  NSString *previewURIString = [incomingRepresentation valueForKeyPath:@"web_meta.preview_url"];
	  NSString *urlPrefix = @"http://invalid.local";
	  NSMutableArray *returnedArray = [NSMutableArray array];
	  NSArray *thumbs = [incomingRepresentation valueForKeyPath:@"web_meta.thumbs"];
	  if ([thumbs count]) {
		for (NSDictionary *thumb in thumbs) {
		  NSString *thumbnailURLString = [urlPrefix stringByAppendingFormat:@"%@%@", previewURIString, thumb[@"id"]];
		  NSDictionary *pageElement = @{@"thumbnailURL": thumbnailURLString, @"page": thumb[@"id"]};
		  [returnedArray addObject:pageElement];
		}
	  }
	  returnedDictionary[@"pageElements"] = returnedArray;

    }
    
  } else if ([incomingFileType isEqualToString:@"doc"]) {
    
    if (incomingRepresentation[@"doc_meta"]) {
      
      NSMutableArray *accessLogArray = [NSMutableArray array];
      for (NSString *accessTime in [incomingRepresentation valueForKeyPath:@"doc_meta.access_time"]) {
        NSString *identifier = [accessTime stringByAppendingString:[incomingRepresentation valueForKeyPath:@"object_id"]];
        NSString *hashedIdentifier = [identifier MD5Sum];
        NSDate *date = [NSDate dateFromISO8601String:accessTime];
        NSDictionary *accessLog = @{
        @"identifier": hashedIdentifier,
        @"accessTime": date,
        @"filePath": [incomingRepresentation valueForKeyPath:@"file_path"],
        @"day": @{@"day" : [date dayBegin]}
        };
        [accessLogArray addObject:accessLog];
      };
      returnedDictionary[@"accessLogs"] = accessLogArray;
      
      NSNumber *pagesValue = [incomingRepresentation valueForKeyPath:@"doc_meta.preview_pages"];
      
      if ([pagesValue isKindOfClass:[NSNumber class]]) {
        
        NSUInteger numberOfPages = [pagesValue unsignedIntegerValue];
        
        NSMutableArray *returnedArray = [NSMutableArray array];
        NSString *ownObjectID = [incomingRepresentation valueForKeyPath:@"object_id"];
        
        for (NSUInteger i = 0; i < numberOfPages; i++) {
		  NSURL *previewURL = [[NSURL URLWithString:@"http://invalid.local"] URLByAppendingPathComponent:@"v3/attachments/view"];
		  NSDictionary *parameters = @{@"object_id": ownObjectID, @"target": @"preview", @"page": @(i + 1)};
		  NSDictionary *pageElement = @{
								  @"thumbnailURL": [IRWebAPIRequestURLWithQueryParameters(previewURL, parameters) absoluteString],
		  @"page": @(i + 1)
		  };
		  [returnedArray addObject:pageElement];
        }
        
        returnedDictionary[@"pageElements"] = returnedArray;
      }
      
    }
    
  } else if ([incomingFileType isEqualToString:@"text"]) {
    
    // ?
    
  }
  
  // only attachments/multiple_get returns attachment meta with md5 or event_time
  if (incomingRepresentation[@"md5"] || incomingRepresentation[@"event_time"]) {
    returnedDictionary[@"outdated"] = @NO;
  }
  
  return returnedDictionary;
  
}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {
  
  if ([aLocalKeyPath isEqualToString:@"remoteFileSize"]) {
    
    if ([aValue isEqual:@""])
      return nil;
    
    if ([aValue isKindOfClass:[NSNumber class]])
      return aValue;
    
    return @([aValue unsignedIntValue]);
    
  }
  
  if ([aLocalKeyPath isEqualToString:@"timestamp"] || [aLocalKeyPath isEqualToString:@"created"]) {
    return [NSDate dateFromISO8601String:aValue];
  }
  
  if ([aLocalKeyPath isEqualToString:@"identifier"])
    return IRWebAPIKitStringValue(aValue);
  
  if ([aLocalKeyPath isEqualToString:@"resourceType"]) {
    
    if (UTTypeConformsTo((__bridge CFStringRef)aValue, kUTTypeItem))
      return aValue;
    
    id returnedValue = IRWebAPIKitStringValue(aValue);
    
    NSArray *possibleTypes = (__bridge_transfer NSArray *)UTTypeCreateAllIdentifiersForTag(kUTTagClassMIMEType, (__bridge CFStringRef)returnedValue, nil);
    
    if ([possibleTypes count]) {
      returnedValue = possibleTypes[0];
    }
    
    //  Incoming stuff is moot (“application/unknown”)
    
    if ([returnedValue hasPrefix:@"dyn."])
      return nil;
    
    return returnedValue;
    
  }
  
  if ([aLocalKeyPath isEqualToString:@"resourceURL"] ||
      [aLocalKeyPath isEqualToString:@"largeThumbnailURL"] ||
      [aLocalKeyPath isEqualToString:@"thumbnailURL"] ||
      [aLocalKeyPath isEqualToString:@"smallThumbnailURL"]) {
    
    if (![aValue length])
      return nil;
    
    NSString *usedPath = [aValue hasPrefix:@"/"] ? aValue : [@"/" stringByAppendingString:aValue];
    return [[NSURL URLWithString:usedPath relativeToURL:[NSURL URLWithString:@"http://invalid.local"]] absoluteString];
    
  }

//  if ([aLocalKeyPath isEqualToString:@"hidden"])
//    return (![aValue isEqual:@"false"] && ![aValue isEqual:@"0"] && ![aValue isEqual:@0]) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;

  return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];
  
}

+ (void) synchronizeWithCompletion:(void (^)(BOOL, NSError *))completionBlock {
  
  [self synchronizeWithOptions:nil completion:completionBlock];
  
}

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {
  
  [NSException raise:NSInternalInconsistencyException format:@"%@ does not support %@.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  
}

- (void) synchronizeWithCompletion:(WAEntitySyncCallback)completionBlock {
  
  [self synchronizeWithOptions:nil completion:completionBlock];
  
}

- (void) synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {
  
  if (!WAIsSyncableObject(self)) {
    
    if (completionBlock)
      completionBlock(NO, nil);
    
    return;
    
  }
  
  WAFileSyncStrategy syncStrategy = options[kWAFileSyncStrategy];
  if (!syncStrategy)
    syncStrategy = kWAFileSyncAdaptiveQualityStrategy;
  
  WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
  WADataStore * const ds = [WADataStore defaultStore];
  NSURL * const ownURL = [[self objectID] URIRepresentation];
  
  BOOL areExpensiveOperationsAllowed = [ri areExpensiveOperationsAllowed];
  
  BOOL canSendResourceImage = NO;
  BOOL canSendThumbnailImage = NO;
  
  if ([syncStrategy isEqual:kWAFileSyncAdaptiveQualityStrategy]) {
    
    canSendResourceImage = areExpensiveOperationsAllowed;
    canSendThumbnailImage = YES;
    
  } else if ([syncStrategy isEqual:kWAFileSyncReducedQualityStrategy]) {
    
    canSendResourceImage = NO;
    canSendThumbnailImage = YES;
    
  } else if ([syncStrategy isEqual:kWAFileSyncFullQualityStrategy]) {
    
    canSendResourceImage = YES;
    canSendThumbnailImage = NO;
    
  }
  
  
  /* Steven: for redmine #1701, there is a strange issue, when we check [self smallestPresentableImage] for needsSendingThumbnailImage here,
   * this will cause the second and other photos will not be copied from Asset Library, an unknown hang in operation queue.
   * The root cause is unknown. But if we didn't call smallestPresetableImage here, it would work fine. As a workaround, we don't test this here
   * And not to invoke smallestPresentableImage for needsSendingThumbnailImage should be fine
   */
  BOOL needsSendingResourceImage = !self.resourceURL;
  BOOL needsSendingThumbnailImage = !self.thumbnailURL;
  
  NSMutableArray *operations = [NSMutableArray array];
  
  BOOL (^isValidPath)(NSString *) = ^ (NSString *aPath) {
    
    //	Bug with extensions:
    //	“application/octet-stream”
    //	crumbles our server
    
    if (![[aPath pathExtension] length])
      return NO;
    
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDirectory])
      return NO;
    
    return (BOOL)!isDirectory;
    
  };
  
  void (^uploadAttachment)(NSURL *, NSMutableDictionary *, IRAsyncOperationCallback) = ^ (NSURL *fileURL, NSMutableDictionary *options, IRAsyncOperationCallback callback) {
    
    NSCParameterAssert(fileURL);
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
      callback(WAFileEntitySyncingError(WAFileSyncingErrorCodePhotoImportDisabled, @"Photo import is disabled, stop sync files", nil));
      return;
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAUseCellularEnabled] && ![[WARemoteInterface sharedInterface] hasWiFiConnection]) {
      callback(WAFileEntitySyncingError(WAFileSyncingErrorCodeSyncNotAllowed, @"Syncing is not allowed, stop sync files", nil));
      return;
    }

    WARemoteInterface *ri = [WARemoteInterface sharedInterface];
    
    [ri createAttachmentWithFile:fileURL group:ri.primaryGroupIdentifier options:options onSuccess: ^ (NSString *attachmentIdentifier) {
      
      [ds performBlock:^{

        NSManagedObjectContext *context = [ds autoUpdatingMOC];
        
        WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
        file.identifier = attachmentIdentifier;
        
        if ([[options valueForKey:kWARemoteAttachmentSubtype] isEqualToString:WARemoteAttachmentMediumSubtype]) {
	
          file.thumbnailURL = [[file class] transformedValue:[@"/v3/attachments/view?object_id=" stringByAppendingFormat:@"%@&image_meta=medium", file.identifier] fromRemoteKeyPath:nil toLocalKeyPath:@"thumbnailURL"];
	
        } else if ([[options valueForKey:kWARemoteAttachmentSubtype] isEqualToString:WARemoteAttachmentOriginalSubtype]) {
	
          file.resourceURL = [[file class] transformedValue:[@"/v3/attachments/view?object_id=" stringByAppendingFormat:@"%@", file.identifier] fromRemoteKeyPath:nil toLocalKeyPath:@"resourceURL"];
	
        }
        
        NSError *error = nil;
        BOOL didSave = [context save:&error];
        NSCAssert1(didSave, @"Generated thumbnail uploaded but metadata is not saved correctly: %@", error);
        
        callback(error);
        
      } waitUntilDone:NO];
      
    } onFailure: ^ (NSError *error) {
      
      // file is existed
      if ([[error domain] isEqualToString:kWARemoteInterfaceDomain] && [error code] == 0x6000 + 14) {

        [ds performBlock:^{
          
          NSManagedObjectContext *context = [ds autoUpdatingMOC];
          
          WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
	
          if ([[options valueForKey:kWARemoteAttachmentSubtype] isEqualToString:WARemoteAttachmentMediumSubtype]) {
	  
            file.thumbnailURL = [[file class] transformedValue:[@"/v3/attachments/view?object_id=" stringByAppendingFormat:@"%@&image_meta=medium", file.identifier] fromRemoteKeyPath:nil toLocalKeyPath:@"thumbnailURL"];
	  
          } else if ([[options valueForKey:kWARemoteAttachmentSubtype] isEqualToString:WARemoteAttachmentOriginalSubtype]) {
	  
            file.resourceURL = [[file class] transformedValue:[@"/v3/attachments/view?object_id=" stringByAppendingFormat:@"%@", file.identifier] fromRemoteKeyPath:nil toLocalKeyPath:@"resourceURL"];
	  
          }
	
          NSError *error = nil;
          BOOL didSave = [context save:&error];
          NSCAssert1(didSave, @"Generated thumbnail uploaded but metadata is not saved correctly: %@", error);
          
          callback(error);
          
        } waitUntilDone:NO];
        
      } else if ([[error domain] isEqualToString:kWAFileEntitySyncingErrorDomain] && [error code] == WAFileSyncingErrorCodeAssetDeleted) {
        
        [ds performBlock:^{

          NSManagedObjectContext *context = [ds autoUpdatingMOC];
	
          WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
	
          if (file.thumbnailURL) {
	  
            // The WAFile never needs sync because its asset has been deleted, but we don't have to hide it.
            // Just keep a hint in its resource URL (all-zero object id)
            file.resourceURL = [[file class] transformedValue:@"/v3/attachments/view?object_id=00000000000000000000000000000000" fromRemoteKeyPath:nil toLocalKeyPath:@"resourceURL"];
            
          } else {
	  
            // Hide the attachment if its thumbnails has not been created.
            file.hidden = @YES;
            file.dirty = @YES;
            
          }
	
          NSError *error = nil;
          [context save:&error];
          callback(error);
          
        } waitUntilDone:NO];
        
      } else {
        
        callback(error);
        
      }
      
    }];
    
  };
  
  if (needsSendingThumbnailImage && canSendThumbnailImage) {
    
    /* this probably won't happen since all selected photos will be generated with thumbnails while composition
     */
    
    [operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
      
      NSManagedObjectContext *context = [ds disposableMOC];
      
      WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
      
      if (file.thumbnailURL) {
        callback(nil);
        return;
      }
      
      NSString *thumbnailFilePath = file.thumbnailFilePath;
      
      NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			        @(WARemoteAttachmentImageType), kWARemoteAttachmentType,
			        WARemoteAttachmentMediumSubtype, kWARemoteAttachmentSubtype,
			        nil];
      
      if (file.identifier) {
        options[kWARemoteAttachmentUpdatedObjectIdentifier] = file.identifier;
      }
      
      NSCAssert1(file.articles.count>0, @"WAFile entity %@ must have already been associated with an article", file);
      WAArticle *article = file.articles[0];  // if the post is from device itself, there should be only one article in db, this should be right, but careful
      if (article.identifier) {
        options[kWARemoteArticleIdentifier] = article.identifier;
      }
      
      if (file.exif) {
        options[kWARemoteAttachmentExif] = file.exif;
      }
      
      if (file.importTime) {
        options[kWARemoteAttachmentImportTime] = file.importTime;
      }
      
      if (!isValidPath(thumbnailFilePath)) {
        
        if (file.assetURL) {
	
	[[WAAssetsLibraryManager defaultManager] assetForURL:[NSURL URLWithString:file.assetURL] resultBlock:^(ALAsset *asset) {
	  
	  if (!asset) {
	    NSLog(@"Asset does not exist for WAFile %@, hide it.", file);
	    file.hidden = @YES;
	    file.dirty = @YES;
	    [context save:nil];
	    callback(nil);
	    return;
	  }

	  [asset makeThumbnailWithOptions:WAThumbnailTypeMedium completeBlock:^(UIImage *image) {
	    
	    NSManagedObjectContext *context = [ds autoUpdatingMOC];
	    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	    
	    WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
	    
	    // Fill EXIF data again to ensure the WAFileExif instance is readable
	    if (file.exif) {
	      options[kWARemoteAttachmentExif] = file.exif;
	    }
	    
	    file.thumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(image, 0.85f) extension:@"jpeg"] path];
	    
	    NSError *error = nil;
	    BOOL didSave = [context save:&error];
	    NSCAssert1(didSave, @"Generated thumbnail could not be saved: %@", error);
	    
	    uploadAttachment([NSURL fileURLWithPath:file.thumbnailFilePath], options, callback);
	    
	  }];
	  
	} failureBlock:^(NSError *error) {
	  
	  NSLog(@"Unable to read asset from url: %@", file.assetURL);
	  callback(error);
	  
	}];
	
        }
        
      } else {
        
        uploadAttachment([NSURL fileURLWithPath:file.thumbnailFilePath], options, callback);
        
      }
      
    } trampoline:^(IRAsyncOperationInvoker callback) {
      
      callback();
      
    } callback:^(id results) {
      
      if ([results isKindOfClass:[NSError class]]) {
        completionBlock(NO, results);
      } else {
        completionBlock(YES, nil);
      }
      
    } callbackTrampoline:^(IRAsyncOperationInvoker callback) {
      
      callback();
      
    }]];
    
  }
  
  if (needsSendingResourceImage && canSendResourceImage) {
    
    [operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
      
      NSManagedObjectContext *context = [ds disposableMOC];
      
      WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
      
      if (file.resourceURL || (![[NSUserDefaults standardUserDefaults] boolForKey:kWABackupFilesToCloudEnabled] && ![[WARemoteInterface sharedInterface] hasReachableStation])) {
        callback(nil);
        return;
      }
      
      NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			        @(WARemoteAttachmentImageType), kWARemoteAttachmentType,
			        WARemoteAttachmentOriginalSubtype, kWARemoteAttachmentSubtype,
			        nil];
      
      if (file.identifier)
        options[kWARemoteAttachmentUpdatedObjectIdentifier] = file.identifier;
      
      WAArticle *article = file.articles[0];
      if (article.identifier) {
        options[kWARemoteArticleIdentifier] = article.identifier;
      }
      
      if (file.exif) {
        options[kWARemoteAttachmentExif] = file.exif;
      }
      
      if (file.timestamp) {
        options[kWARemoteAttachmentCreateTime] = file.timestamp;
      }
      
      if (file.importTime) {
        options[kWARemoteAttachmentImportTime] = file.importTime;
      }
      
      NSString *sentResourcePath = file.resourceFilePath;
      if (!isValidPath(sentResourcePath)) {
        if (file.assetURL) {
	uploadAttachment([NSURL URLWithString:file.assetURL], options, callback);
        }
      } else {
        uploadAttachment([NSURL fileURLWithPath:sentResourcePath], options, callback);
      }
      
    } trampoline:^(IRAsyncOperationInvoker callback) {
      
      callback();
      
    } callback:^(id results) {
      
      if ([results isKindOfClass:[NSError class]]) {
        completionBlock(NO, results);
      } else {
        completionBlock(YES, nil);
      }
      
    } callbackTrampoline:^(IRAsyncOperationInvoker callback) {
      
      callback();
      
    }]];
    
  }
  
  [operations enumerateObjectsUsingBlock:^(IRAsyncBarrierOperation *op, NSUInteger idx, BOOL *stop) {
    if (idx > 0)
      [op addDependency:(IRAsyncBarrierOperation *)operations[(idx - 1)]];
  }];
  
  IRAsyncOperation *lastOperation = [[[[self class] sharedSyncQueue] operations] lastObject];
  if (lastOperation) {
    [operations[0] addDependency:lastOperation];
  }

  [[[self class] sharedSyncQueue] addOperations:operations waitUntilFinished:NO];
  
}

+ (NSOperationQueue *) sharedSyncQueue {
  
  static NSOperationQueue *queue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    
  });
  
  return queue;
  
}

@end
