//
//  WAFile+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAFile+WARemoteInterfaceEntitySyncing.h"
#import "WADataStore.h"
#import "WARemoteInterface.h"

@implementation WAFile (WARemoteInterfaceEntitySyncing)

- (void) configureWithRemoteDictionary:(NSDictionary *)inDictionary {

  NSMutableDictionary *usedDictionary = [[inDictionary mutableCopy] autorelease];
  
  if ([[usedDictionary objectForKey:@"url"] isEqualToString:@""])
    [usedDictionary removeObjectForKey:@"url"];

  [super configureWithRemoteDictionary:inDictionary];
  
  if (!self.resourceType) {
    
    NSString *pathExtension = [self.remoteFileName pathExtension];
    if (pathExtension) {
      
      CFStringRef preferredUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)pathExtension, NULL);
      [NSMakeCollectable(preferredUTI) autorelease];
      
      self.resourceType = (NSString *)preferredUTI;

    }
    
  }
  
  if (!self.thumbnailURL)
  if (self.remoteRepresentedImage)
    self.thumbnailURL = [[self class] transformedValue:self.remoteRepresentedImage fromRemoteKeyPath:nil toLocalKeyPath:@"thumbnailURL"];        
  
  if (!self.resourceURL)
  if (self.identifier)
    self.resourceURL = [[self class] transformedValue:[@"/v2/attachments/view?object_id=" stringByAppendingFormat:self.identifier] fromRemoteKeyPath:nil toLocalKeyPath:@"resourceURL"];
  
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
		
			//	@"article", @"article",
			@"codeName", @"code_name",
			//	@"owner", @"owner",
			@"text", @"description",
			@"creationDeviceIdentifier", @"device_id",
			@"remoteFileName", @"file_name",
			@"remoteFileSize", @"file_size",
			//	@"group", @"group",
			@"remoteRepresentedImage", @"image",
			@"remoteResourceHash", @"md5",
			@"resourceType", @"mime_type",
			@"identifier", @"object_id",
			@"title", @"title",
			@"remoteResourceType", @"type",
			@"thumbnailURL", @"thumbnail_url",
			@"resourceURL", @"url",
			@"timestamp", @"timestamp",
      
      @"pageElements", @"pageElements",
			
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"WAFilePageElement", @"pageElements",
	
	nil];

}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSMutableDictionary *returnedDictionary = [[incomingRepresentation mutableCopy] autorelease];
	
	NSString *mediumImageRepURLString = [returnedDictionary valueForKeyPath:@"image_meta.medium.url"];
	if ([mediumImageRepURLString isKindOfClass:[NSString class]])
    [returnedDictionary setObject:mediumImageRepURLString forKey:@"thumbnail_url"];
  
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
	
		if (UTTypeConformsTo((CFStringRef)aValue, kUTTypeItem))
			return aValue;
		 
		id returnedValue = IRWebAPIKitStringValue(aValue);
		
		CFArrayRef possibleTypes = UTTypeCreateAllIdentifiersForTag(kUTTagClassMIMEType, (CFStringRef)returnedValue, nil);
		
		if (CFArrayGetCount(possibleTypes) > 0) {
			//	NSLog(@"Warning: tried to set a MIME type for a UTI tag.");
			returnedValue = CFArrayGetValueAtIndex(possibleTypes, 0);
		}
    
    //  Incoming stuff is moot (“application/unknown”)
    
    if ([returnedValue hasPrefix:@"dyn."])
      return nil;
    
		return returnedValue;
		
	}
	
	if ([aLocalKeyPath isEqualToString:@"resourceURL"] || [aLocalKeyPath isEqualToString:@"thumbnailURL"]) {
  
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

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(void (^)(BOOL, NSManagedObjectContext *, NSArray *, NSError *))completionBlock {

  [NSException raise:NSInternalInconsistencyException format:@"%@ does not support %@.", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
  
}

- (void) synchronizeWithCompletion:(void (^)(BOOL, NSManagedObjectContext *, NSManagedObject *, NSError *))completionBlock {

  [self synchronizeWithOptions:nil completion:completionBlock];
  
}

- (void) synchronizeWithOptions:(NSDictionary *)options completion:(void (^)(BOOL, NSManagedObjectContext *, NSManagedObject *, NSError *))completionBlock {

	NSParameterAssert(WAObjectEligibleForRemoteInterfaceEntitySyncing(self));

	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	NSURL *ownURL = [[self objectID] URIRepresentation];
	

	if (([[NSURL URLWithString:self.resourceURL] isFileURL] || !self.resourceURL) && (self.resourceFilePath)) {
	
		[ri createAttachmentWithFileAtURL:[NSURL URLWithString:self.resourceURL] inGroup:ri.primaryGroupIdentifier representingImageURL:nil withTitle:self.text description:nil replacingAttachment:nil asType:nil onSuccess:^(NSString *attachmentIdentifier) {
		
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			
			WAFile *savedFile = (WAFile *)[context irManagedObjectForURI:ownURL];
			savedFile.identifier = attachmentIdentifier;
		
			if (completionBlock)
				completionBlock(YES, context, savedFile, nil);
			
		} onFailure:^(NSError *error) {
		
			if (completionBlock)
				completionBlock(NO, nil, nil, error);
			
		}];
	
	} else {
	
		[ri retrieveAttachment:self.identifier onSuccess:^(NSDictionary *attachmentRep) {
			
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			
			WAFile *savedFile = (WAFile *)[context irManagedObjectForURI:ownURL];
			[savedFile configureWithRemoteDictionary:attachmentRep];
		
			if (completionBlock)
				completionBlock(YES, context, savedFile, nil);
			
		} onFailure:^(NSError *error) {
		
			if (completionBlock)
				completionBlock(NO, nil, nil, error);
			
		}];
	
	}

}

@end
