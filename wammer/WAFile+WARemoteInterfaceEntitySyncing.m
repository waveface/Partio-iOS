//
//  WAFile+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "IRAsyncOperation.h"

#import "WAFile+WARemoteInterfaceEntitySyncing.h"
#import "WADataStore.h"
#import "WARemoteInterface.h"

#import "UIImage+IRAdditions.h"
#import "UIImage+WAAdditions.h"
#import "QuartzCore+IRAdditions.h"


NSString * kWAFileEntitySyncingErrorDomain = @"com.waveface.wammer.file.entitySyncing";

#define kWAFileEntitySyncingError(code, descriptionKey, reasonKey) [NSError irErrorWithDomain:kWAFileEntitySyncingErrorDomain code:code descriptionLocalizationKey:descriptionKey reasonLocalizationKey:reasonKey userInfo:nil]


NSString * const kWAFileSyncStrategy = @"WAFileSyncStrategy";
NSString * const kWAFileSyncDefaultStrategy = @"WAFileSyncDefaultStrategy";
NSString * const kWAFileSyncAdaptiveQualityStrategy = @"WAFileSyncAdaptiveQualityStrategy";
NSString * const kWAFileSyncReducedQualityStrategy = @"WAFileSyncReducedQualityStrategy";
NSString * const kWAFileSyncFullQualityStrategy = @"WAFileSyncFullQualityStrategy";


@implementation WAFile (WARemoteInterfaceEntitySyncing)

- (void) configureWithRemoteDictionary:(NSDictionary *)inDictionary {
 
	NSMutableDictionary *usedDictionary = [inDictionary mutableCopy];
  
  if ([[usedDictionary objectForKey:@"url"] isEqualToString:@""])
    [usedDictionary removeObjectForKey:@"url"];
	
  [super configureWithRemoteDictionary:usedDictionary];
  
  if (!self.resourceType) {
    
    NSString *pathExtension = [self.remoteFileName pathExtension];
    if (pathExtension) {
      
      CFStringRef preferredUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, NULL);
      self.resourceType = (__bridge_transfer NSString *)preferredUTI;

    }
    
  }
  
  if (!self.thumbnailURL)
  if (self.remoteRepresentedImage)
    self.thumbnailURL = [[self class] transformedValue:self.remoteRepresentedImage fromRemoteKeyPath:nil toLocalKeyPath:@"thumbnailURL"];        
  
  if (!self.resourceURL)
  if (self.identifier && self.remoteResourceHash)
    self.resourceURL = [[self class] transformedValue:[@"/v2/attachments/view?object_id=" stringByAppendingFormat:@"%@", self.identifier] fromRemoteKeyPath:nil toLocalKeyPath:@"resourceURL"];
  
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
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
		
			@"codeName", @"code_name",
			
			@"text", @"description",
			@"creationDeviceIdentifier", @"device_id",
			@"remoteFileName", @"file_name",
			@"remoteFileSize", @"file_size",
			
			@"remoteRepresentedImage", @"image",
			@"remoteResourceHash", @"md5",
			@"resourceType", @"mime_type",
			@"identifier", @"object_id",
			@"title", @"title",
			@"remoteResourceType", @"type",
			
			@"smallThumbnailURL", @"small_thumbnail_url",
			@"thumbnailURL", @"thumbnail_url",
			@"largeThumbnailURL", @"large_thumbnail_url",
			
			@"resourceURL", @"url",
			@"timestamp", @"timestamp",
      
			@"pageElements", @"pageElements",
			
		nil];
		
	});

	return mapping;

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"WAFilePageElement", @"pageElements",
	
	nil];

}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSMutableDictionary *returnedDictionary = [incomingRepresentation mutableCopy];
	
	NSString *smallImageRepURLString = [returnedDictionary valueForKeyPath:@"image_meta.small.url"];
	if ([smallImageRepURLString isKindOfClass:[NSString class]])
    [returnedDictionary setObject:smallImageRepURLString forKey:@"small_thumbnail_url"];
 
	NSString *mediumImageRepURLString = [returnedDictionary valueForKeyPath:@"image_meta.medium.url"];
	if ([mediumImageRepURLString isKindOfClass:[NSString class]])
    [returnedDictionary setObject:mediumImageRepURLString forKey:@"thumbnail_url"];
  
	NSString *largeImageRepURLString = [returnedDictionary valueForKeyPath:@"image_meta.large.url"];
	if ([largeImageRepURLString isKindOfClass:[NSString class]])
    [returnedDictionary setObject:largeImageRepURLString forKey:@"large_thumbnail_url"];
	
	NSString *incomingFileType = [incomingRepresentation objectForKey:@"type"];
  
  if ([incomingFileType isEqualToString:@"image"]) {
  
    //  ?
  
  } else if ([incomingFileType isEqualToString:@"doc"]) {
  
    NSNumber *pagesValue = [incomingRepresentation valueForKeyPath:@"doc_meta.pages"];
    
    if ([pagesValue isKindOfClass:[NSNumber class]]) {
    
      NSUInteger numberOfPages = [pagesValue unsignedIntegerValue];
      
      [returnedDictionary setObject:((^ {
      
        NSMutableArray *returnedArray = [NSMutableArray array];
        NSString *ownObjectID = [incomingRepresentation valueForKeyPath:@"object_id"];
        
        for (NSUInteger i = 0; i < numberOfPages; i++) {
        
          [returnedArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
          
            [IRWebAPIRequestURLWithQueryParameters(
              
              [[NSURL URLWithString:@"http://invalid.local"] URLByAppendingPathComponent:@"v2/attachments/view"],
              
              [NSDictionary dictionaryWithObjectsAndKeys:
                ownObjectID, @"object_id",
                @"slide", @"target",
                [NSNumber numberWithUnsignedInt:(i + 1)], @"page",
              nil]
              
            ) absoluteString], @"thumbnailURL",
          
          nil]];
        
        }
        
        return returnedArray;
      
      })()) forKey:@"pageElements"];
    
    }
  
  } else if ([incomingFileType isEqualToString:@"text"]) {
    
    // ?
      
  }
	
	return returnedDictionary; 

}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

  if ([aLocalKeyPath isEqualToString:@"remoteFileSize"]) {
    
    if ([aValue isEqual:@""])
      return nil;
  
    if ([aValue isKindOfClass:[NSNumber class]])
      return aValue;
    
    return [NSNumber numberWithUnsignedInt:[aValue unsignedIntValue]];
    
  }
  
	if ([aLocalKeyPath isEqualToString:@"timestamp"])
		return [[WADataStore defaultStore] dateFromISO8601String:aValue];
	
	if ([aLocalKeyPath isEqualToString:@"identifier"])
		return IRWebAPIKitStringValue(aValue);
		
	if ([aLocalKeyPath isEqualToString:@"resourceType"]) {
	
		if (UTTypeConformsTo((__bridge CFStringRef)aValue, kUTTypeItem))
			return aValue;
		 
		id returnedValue = IRWebAPIKitStringValue(aValue);
		
		NSArray *possibleTypes = (__bridge_transfer NSArray *)UTTypeCreateAllIdentifiersForTag(kUTTagClassMIMEType, (__bridge CFStringRef)returnedValue, nil);
		
		if ([possibleTypes count]) {
			returnedValue = [possibleTypes objectAtIndex:0];
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
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

+ (void) synchronizeWithCompletion:(void (^)(BOOL, NSManagedObjectContext *, NSArray *, NSError *))completionBlock {

  [self synchronizeWithOptions:nil completion:completionBlock];
  
}

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {

  [NSException raise:NSInternalInconsistencyException format:@"%@ does not support %@.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  
}

- (void) synchronizeWithCompletion:(WAEntitySyncCallback)completionBlock {

  [self synchronizeWithOptions:nil completion:completionBlock];
  
}	

- (void) synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {

	NSParameterAssert(WAIsSyncableObject(self));
	
	WAFileSyncStrategy syncStrategy = [options objectForKey:kWAFileSyncStrategy];
	if (!syncStrategy)
		syncStrategy = kWAFileSyncAdaptiveQualityStrategy;

	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	WADataStore * const ds = [WADataStore defaultStore];
	NSURL * const ownURL = [[self objectID] URIRepresentation];
	NSFileManager * const fm = [NSFileManager defaultManager];
	
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
		canSendThumbnailImage = YES;
	
	}
	
	BOOL needsSendingResourceImage = !self.resourceURL;
	BOOL needsSendingThumbnailImage = !self.thumbnailURL;
	
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
	
	if (!isValidPath(self.resourceFilePath)) {
		NSLog(@"Resource file path %@ is not valid.  Skipping.", self.resourceFilePath);
		canSendResourceImage = NO;
	}
	
	NSMutableArray *operations = [NSMutableArray array];
	NSManagedObjectContext *context = [ds disposableMOC];
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	
	if (needsSendingThumbnailImage && canSendThumbnailImage) {
	
		[operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
			
			WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
			
			NSString *thumbnailFilePath = file.thumbnailFilePath;
			if (!isValidPath(thumbnailFilePath)) {
			
				UIImage *smallestImage = [file smallestPresentableImage];
				CGSize usedThumbnailSize = IRGravitize((CGRect){ CGPointZero, (CGSize){ 512, 512 } }, smallestImage.size, kCAGravityResizeAspect).size;
				
				UIImage *thumbnailImage = [smallestImage irScaledImageWithSize:usedThumbnailSize];
				thumbnailFilePath = [[ds persistentFileURLForData:UIImagePNGRepresentation(thumbnailImage) extension:@"png"] path];
				file.thumbnailFilePath = thumbnailFilePath;
				
				NSError *error = nil;
				
				BOOL didSave = [context save:&error];
				NSCAssert1(didSave, @"Generated thumbnail could not be saved: %@", error);
			
			}
			
			NSParameterAssert(thumbnailFilePath);
			NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]);
			
			NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInteger:WARemoteAttachmentImageType], kWARemoteAttachmentType,
				WARemoteAttachmentMediumSubtype, kWARemoteAttachmentSubtype,
				file.identifier, kWARemoteAttachmentUpdatedObjectIdentifier,
			nil];
			
			[ri createAttachmentWithFile:[NSURL fileURLWithPath:thumbnailFilePath] group:ri.primaryGroupIdentifier options:options onSuccess: ^ (NSString *attachmentIdentifier) {
			
				[context performBlock:^{
					
					WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
					file.identifier = attachmentIdentifier;
					file.thumbnailURL = [[file class] transformedValue:[@"/v2/attachments/view?object_id=" stringByAppendingFormat:@"%@&image_meta=medium", file.identifier] fromRemoteKeyPath:nil toLocalKeyPath:@"thumbnailURL"];
					
					NSError *error = nil;
					BOOL didSave = [context save:&error];
					NSCAssert1(didSave, @"Generated thumbnail uploaded but metadata is not saved correctly: %@", error);
					
					callback(attachmentIdentifier);
					
				}];
									
			} onFailure: ^ (NSError *error) {
			
				callback(error);
									
			}];
							
		} trampoline:^(IRAsyncOperationInvoker block) {
		
			[context performBlock:block];
			
		} callback:nil callbackTrampoline:^(IRAsyncOperationInvoker block) {
		
			[context performBlock:block];
			
		}]];
	
	}
	
	if (needsSendingResourceImage && canSendResourceImage) {
	
		[operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
			
			WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
			
			NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInteger:WARemoteAttachmentImageType], kWARemoteAttachmentType,
				WARemoteAttachmentOriginalSubtype, kWARemoteAttachmentSubtype,
			nil];
			
			if (file.identifier)
				[options setObject:file.identifier forKey:kWARemoteAttachmentUpdatedObjectIdentifier];
			
			NSString *sentResourcePath = file.resourceFilePath;
			
			[ri createAttachmentWithFile:[NSURL fileURLWithPath:sentResourcePath] group:ri.primaryGroupIdentifier options:options onSuccess: ^ (NSString *attachmentIdentifier) {
			
				[context performBlock:^{
					
					WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
					file.identifier = attachmentIdentifier;
					file.resourceURL = [[file class] transformedValue:[@"/v2/attachments/view?object_id=" stringByAppendingFormat:@"%@", file.identifier] fromRemoteKeyPath:nil toLocalKeyPath:@"resourceURL"];
					
					[context save:nil];
					
					callback(attachmentIdentifier);

				}];
				
			} onFailure: ^ (NSError *error) {
			
				callback(error);
				
			}];

		} trampoline:^(IRAsyncOperationInvoker block) {
			
			[context performBlock:block];
			
		} callback:nil callbackTrampoline:^(IRAsyncOperationInvoker block) {
		
			[context performBlock:block];
			
		}]];
	
	}
	
	[operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
		
		WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];

		if (file.identifier) {
		
			[ri retrieveAttachment:file.identifier onSuccess:^(NSDictionary *attachmentRep) {
				
				callback(attachmentRep);

			} onFailure:^(NSError *error) {
			
				callback(error);
				
			}];
		
		} else {
		
			callback(nil);
		
		}

	} trampoline:^(IRAsyncOperationInvoker block) {
	
		[context performBlock:block];
		
	} callback:^(id results) {
		
		if ([results isKindOfClass:[NSDictionary class]]) {
		
			WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
			[file configureWithRemoteDictionary:(NSDictionary *)results];
			
			NSError *error = nil;
			BOOL didSave = [context save:&error];
			NSCAssert1(didSave, @"File entity syncing should merge remote information: %@", error);
		
			if (completionBlock)
				completionBlock(didSave, context, [NSArray arrayWithObject:file], didSave ? nil : error);

		} else if ([results isKindOfClass:[NSError class]]){
		
			if (completionBlock)
				completionBlock(NO, nil, nil, (NSError *)results);

		} else {
		
			if (completionBlock)
				completionBlock(NO, nil, nil, nil);

		}

	} callbackTrampoline:^(IRAsyncOperationInvoker block) {
		
		[context performBlock:block];

	}]];
	
	
	__block NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[operations addObject:[NSBlockOperation blockOperationWithBlock:^ {
		queue = nil;
	}]];
	[queue setSuspended:YES];
	[operations enumerateObjectsUsingBlock:^(IRAsyncBarrierOperation *op, NSUInteger idx, BOOL *stop) {
		if (idx > 0)
			[op addDependency:(IRAsyncBarrierOperation *)[operations objectAtIndex:(idx - 1)]];
	}];
	[queue addOperations:operations waitUntilFinished:NO];
	[queue setSuspended:NO];

}

@end
