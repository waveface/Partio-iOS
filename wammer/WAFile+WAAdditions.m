//
//  WAFile+WAAdditions.m
//  wammer
//
//  Created by Evadne Wu on 1/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <objc/runtime.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIDevice.h>
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif


#import "WAFile+WAAdditions.h"

#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "UIImage+IRAdditions.h"
#import "CGGeometry+IRAdditions.h"

#import "IRLifetimeHelper.h"


NSString * const kWAFileResourceImage = @"resourceImage";
NSString * const kWAFileResourceURL = @"resourceURL";
NSString * const kWAFileResourceFilePath = @"resourceFilePath";
NSString * const kWAFileThumbnailImage = @"thumbnailImage";
NSString * const kWAFileThumbnailURL = @"thumbnailURL";
NSString * const kWAFileThumbnailFilePath = @"thumbnailFilePath";
NSString * const kWAFileLargeThumbnailImage = @"largeThumbnailImage";
NSString * const kWAFileLargeThumbnailURL = @"largeThumbnailURL";
NSString * const kWAFileLargeThumbnailFilePath = @"largeThumbnailFilePath";
NSString * const kWAFileValidatesResourceImage = @"validatesResourceImage";
NSString * const kWAFileValidatesThumbnailImage = @"validatesThumbnailImage";
NSString * const kWAFileValidatesLargeThumbnailImage = @"validatesLargeThumbnailImage";
NSString * const kWAFilePresentableImage = @"presentableImage";


@implementation WAFile (WAAdditions)

# pragma mark - Lifecycle

- (void) awakeFromFetch {

  [super awakeFromFetch];
  
  [self irReconcileObjectOrderWithKey:@"pageElements" usingArrayKeyed:@"pageElementOrder"];

}

- (NSArray *) pageElementOrder {

  return [self irBackingOrderArrayKeyed:@"pageElementOrder"];

}

- (void) didChangeValueForKey:(NSString *)inKey withSetMutation:(NSKeyValueSetMutationKind)inMutationKind usingObjects:(NSSet *)inObjects {

  [super didChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
  
  if ([inKey isEqualToString:@"pageElements"]) {
    
    [self irUpdateObjects:inObjects withRelationshipKey:@"pageElements" usingOrderArray:@"pageElementOrder" withSetMutation:inMutationKind];
    
  }

}


# pragma mark - Blob Retrieval Scheduling

- (BOOL) canScheduleBlobRetrieval {

	if ([[self objectID] isTemporaryID])
		return NO;
	
	//	if (![self isInserted])
	//		return NO;
	
	if ([self isDeleted])
		return NO;
	
	return YES;

}

- (BOOL) canScheduleExpensiveBlobRetrieval {

	if (![self canScheduleBlobRetrieval])
		return NO;

	if (![[WARemoteInterface sharedInterface] areExpensiveOperationsAllowed])
		return NO;
	
	return YES;
	
}

- (void) scheduleResourceRetrievalIfPermitted {

	if (![self canScheduleExpensiveBlobRetrieval])
		return;

	NSURL *ownURL = [[self objectID] URIRepresentation];
	NSURL *resourceURL = [NSURL URLWithString:self.resourceURL];
	
	[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:resourceURL usingPriority:NSOperationQueuePriorityLow forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
		
		dispatch_async([[self class] sharedResourceHandlingQueue], ^ {

			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
			[file takeResourceFromTemporaryFile:[tempFileURLOrNil path] matchingURL:resourceURL];
			
			NSError *savingError = nil;
			if (![context save:&savingError])
				NSLog(@"Error saving: %@", savingError);
			
		});
		
	}];
		
}

- (void) scheduleThumbnailRetrievalIfPermitted {

	if (![self canScheduleBlobRetrieval])
		return;
	
	NSURL *ownURL = [[self objectID] URIRepresentation];
	NSURL *thumbnailURL = [NSURL URLWithString:self.thumbnailURL];
	
	[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:thumbnailURL usingPriority:NSOperationQueuePriorityHigh forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
		
		dispatch_async([[self class] sharedResourceHandlingQueue], ^ {

			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
			[file takeThumbnailFromTemporaryFile:[tempFileURLOrNil path] matchingURL:thumbnailURL];
			
			NSError *savingError = nil;
			if (![context save:&savingError])
				NSLog(@"Error saving: %@", savingError);
			
		});
		
	}];

}

- (void) scheduleLargeThumbnailRetrievalIfPermitted {

	if (![self canScheduleBlobRetrieval])
		return;
	
	NSURL *ownURL = [[self objectID] URIRepresentation];
	NSURL *largeThumbnailURL = [NSURL URLWithString:self.largeThumbnailURL];
	
	[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:largeThumbnailURL usingPriority:NSOperationQueuePriorityNormal forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
		
		dispatch_async([[self class] sharedResourceHandlingQueue], ^ {

			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
			[file takeLargeThumbnailFromTemporaryFile:[tempFileURLOrNil path] matchingURL:largeThumbnailURL];
			
			NSError *savingError = nil;
			if (![context save:&savingError])
				NSLog(@"Error saving: %@", savingError);
			
		});
		
	}];
	
}

- (BOOL) takeResourceFromTemporaryFile:(NSString *)aPath matchingURL:(NSURL *)anURL {
	return [self takeBlobFromTemporaryFile:aPath forKeyPath:@"resourceFilePath" matchingURL:anURL forKeyPath:@"resourceURL"];
}

- (BOOL) takeThumbnailFromTemporaryFile:(NSString *)aPath matchingURL:(NSURL *)anURL {
	return [self takeBlobFromTemporaryFile:aPath forKeyPath:@"thumbnailFilePath" matchingURL:anURL forKeyPath:@"thumbnailURL"];
}

- (BOOL) takeLargeThumbnailFromTemporaryFile:(NSString *)aPath matchingURL:(NSURL *)anURL {
	return [self takeBlobFromTemporaryFile:aPath forKeyPath:@"largeThumbnailFilePath" matchingURL:anURL forKeyPath:@"largeThumbnailURL"];
}

- (BOOL) takeBlobFromTemporaryFile:(NSString *)aPath forKeyPath:(NSString *)fileKeyPath matchingURL:(NSURL *)anURL forKeyPath:(NSString *)urlKeyPath {

	@try {
		[self primitiveValueForKey:[(NSPropertyDescription *)[[self.entity properties] lastObject] name]];
	} @catch (NSException *exception) {
		NSLog(@"Got access exception: %@", exception);
	}

	NSString *currentFilePath = [self primitiveValueForKey:fileKeyPath];
	if (currentFilePath || ![[self valueForKey:urlKeyPath] isEqualToString:[anURL absoluteString]]) {
		NSLog(@"Skipping double-writing");
		return NO;
	}
	
	NSURL *fileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:[NSURL fileURLWithPath:aPath]];
	
	NSString *ownResourceType = self.resourceType;
	NSString *preferredExtension = nil;
	if (ownResourceType)
		preferredExtension = [NSMakeCollectable(UTTypeCopyPreferredTagWithClass((CFStringRef)ownResourceType, kUTTagClassFilenameExtension)) autorelease];
	
	if (preferredExtension) {
		
		NSURL *newFileURL = [NSURL fileURLWithPath:[[[fileURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:preferredExtension]];
		
		NSError *movingError = nil;
		BOOL didMove = [[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:newFileURL error:&movingError];
		if (!didMove) {
			NSLog(@"Error moving: %@", movingError);
			return NO;
		}
			
		fileURL = newFileURL;
		
	}
	
	[self setValue:[fileURL path] forKey:fileKeyPath];
	
	return YES;

}


# pragma mark - File Path Accessors & Triggers

- (void) setResourceFilePath:(NSString *)newResourceFilePath {

	[self willChangeValueForKey:kWAFileResourceFilePath];
	
	[self setPrimitiveResourceFilePath:newResourceFilePath];
	//	[self setResourceImage:nil];
	[self setValidatesResourceImage:!!newResourceFilePath];
	
	[self didChangeValueForKey:kWAFileResourceFilePath];
	
}

- (void) setThumbnailFilePath:(NSString *)newThumbnailFilePath {
	
	[self willChangeValueForKey:kWAFileThumbnailFilePath];
	
	[self setPrimitiveThumbnailFilePath:newThumbnailFilePath];
	[self setThumbnailImage:nil];
	[self setValidatesThumbnailImage:!!newThumbnailFilePath];
	
	[self didChangeValueForKey:kWAFileThumbnailFilePath];
	
}

- (void) setLargeThumbnailFilePath:(NSString *)newLargeThumbnailFilePath {
	
	[self willChangeValueForKey:kWAFileLargeThumbnailFilePath];
	
	[self setPrimitiveLargeThumbnailFilePath:newLargeThumbnailFilePath];
	[self setLargeThumbnailImage:nil];
	[self setValidatesLargeThumbnailImage:!!newLargeThumbnailFilePath];
	
	[self didChangeValueForKey:kWAFileLargeThumbnailFilePath];
	
}

- (NSString *) resourceFilePath {

	NSString *primitivePath = [self primitiveValueForKey:@"resourceFilePath"];
	
	if (primitivePath)
		return primitivePath;
	
	if (!self.resourceURL)
		return nil;
	
	NSURL *resourceURL = [NSURL URLWithString:self.resourceURL];

	if ([resourceURL isFileURL]) {
		self.resourceFilePath = (primitivePath = [resourceURL path]);
		return primitivePath;
	}
	
	[self scheduleResourceRetrievalIfPermitted];
	
	return nil;

}

- (NSString *) thumbnailFilePath {

	NSString *primitivePath = [self primitiveValueForKey:@"thumbnailFilePath"];
	
	if (primitivePath)
		return primitivePath;
	
	if (!self.thumbnailURL)
		return nil;
	
	NSURL *thumbnailURL = [NSURL URLWithString:self.thumbnailURL];
	
	if ([thumbnailURL isFileURL]) {
		self.thumbnailFilePath = (primitivePath = [thumbnailURL path]);
		return primitivePath;
	}
	
	[self scheduleThumbnailRetrievalIfPermitted];
	
	return nil;

}

- (NSString *) largeThumbnailFilePath {

	NSString *primitivePath = [self primitiveValueForKey:kWAFileLargeThumbnailFilePath];
	
	if (primitivePath)
		return primitivePath;
	
	if (!self.largeThumbnailURL)
		return nil;
	
	NSURL *largeThumbnailURL = [NSURL URLWithString:self.largeThumbnailURL];
	
	if ([largeThumbnailURL isFileURL]) {
		self.largeThumbnailFilePath = (primitivePath = [largeThumbnailURL path]);
		return primitivePath;
	}
	
	[self scheduleLargeThumbnailRetrievalIfPermitted];
	
	return nil;

}

- (BOOL) validateForDelete:(NSError **)error {

	if (![super validateForDelete:error])
		return NO;
	
	if (![self validateThumbnailImageIfNeeded:error])
		return NO;
	
	if (![self validateLargeThumbnailImageIfNeeded:error])
		return NO;

	if (![self validateResourceImageIfNeeded:error])
		return NO;
	
	return YES;

}

- (BOOL) validateForInsert:(NSError **)error {

	if (![super validateForInsert:error])
		return NO;
	
	if (![self validateThumbnailImageIfNeeded:error])
		return NO;
	
	if (![self validateLargeThumbnailImageIfNeeded:error])
		return NO;

	if (![self validateResourceImageIfNeeded:error])
		return NO;

	return YES;

}

- (BOOL) validateForUpdate:(NSError **)error {

	if (![super validateForUpdate:error])
		return NO;
	
	if (![self validateThumbnailImageIfNeeded:error])
		return NO;
	
	if (![self validateLargeThumbnailImageIfNeeded:error])
		return NO;

	if (![self validateResourceImageIfNeeded:error])
		return NO;
		
	return YES;

}

- (void) prepareForDeletion {

	[super prepareForDeletion];
	
	NSString *thumbnailPath = [self primitiveValueForKey:kWAFileThumbnailFilePath];
	NSString *largeThumbnailPath = [self primitiveValueForKey:kWAFileLargeThumbnailFilePath];
	NSString *resourcePath = [self primitiveValueForKey:kWAFileResourceFilePath];
	
	if (thumbnailPath)
		[[NSFileManager defaultManager] removeItemAtPath:thumbnailPath error:nil];

	if (largeThumbnailPath)
		[[NSFileManager defaultManager] removeItemAtPath:largeThumbnailPath error:nil];
	
	if (resourcePath)
		[[NSFileManager defaultManager] removeItemAtPath:resourcePath error:nil];
	
}


# pragma mark - Validation

- (BOOL) validateResourceImageIfNeeded:(NSError **)outError {
	return self.validatesResourceImage ? [self validateResourceImage:outError] : YES;
}
- (BOOL) validateResourceImageIfNeeded {
	return [self validateResourceImageIfNeeded:nil];
}
- (BOOL) validateResourceImage:(NSError **)outError {
	return [[self class] validateImageAtPath:[self primitiveValueForKey:@"resourceFilePath"] error:outError];
}
- (BOOL) validateResourceImage {
	return [self validateResourceImage:nil];	
}

- (BOOL) validateThumbnailImageIfNeeded:(NSError **)outError {
	return self.validatesThumbnailImage ? [self validateThumbnailImage:outError] : YES;
}
- (BOOL) validateThumbnailImageIfNeeded {
	return [self validateThumbnailImageIfNeeded:nil];
}
- (BOOL) validateThumbnailImage:(NSError **)outError {
	return [[self class] validateImageAtPath:[self primitiveValueForKey:@"thumbnailFilePath"] error:outError];
}
- (BOOL) validateThumbnailImage {
	return [self validateThumbnailImage:nil];
}

- (BOOL) validateLargeThumbnailImageIfNeeded:(NSError **)outError {
	return self.validatesLargeThumbnailImage ? [self validateLargeThumbnailImage:outError] : YES;
}
- (BOOL) validateLargeThumbnailImageIfNeeded {	
	return [self validateLargeThumbnailImageIfNeeded:nil];
}
- (BOOL) validateLargeThumbnailImage:(NSError **)outError {
	return [[self class] validateImageAtPath:[self primitiveValueForKey:kWAFileLargeThumbnailFilePath] error:outError];	
}
- (BOOL) validateLargeThumbnailImage {
	return [self validateLargeThumbnailImage:nil];
}

+ (BOOL) validateImageAtPath:(NSString *)aFilePath error:(NSError **)error {

	error = error ? error : &(NSError *){ nil };
	
	if (aFilePath && ![[NSFileManager defaultManager] fileExistsAtPath:aFilePath]) {
		
		*error = [NSError errorWithDomain:@"com.waveface.wammer.dataStore.file" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithFormat:@"Image at %@ is actually nonexistant", aFilePath], NSLocalizedDescriptionKey,
		nil]];
		
		return NO;
		
	} else if (![UIImage imageWithData:[NSData dataWithContentsOfMappedFile:aFilePath]]) {
		
		*error = [NSError errorWithDomain:@"com.waveface.wammer.dataStore.file" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSString stringWithFormat:@"Image at %@ can’t be decoded", aFilePath], NSLocalizedDescriptionKey,
		nil]];
		
		return NO;
		
	}

	return YES;

}


# pragma mark - Presentable Image

+ (NSSet *) keyPathsForValuesAffectingPresentableImage {

	return [NSSet setWithObjects:
		@"thumbnailURL",
		@"largeThumbnailURL",
		@"resourceURL",
		@"thumbnailFilePath",
		@"largeThumbnailFilePath",
		@"resourceFilePath",
	nil];

}

- (UIImage *) presentableImage {

	if ([self resourceFilePath])
		return self.resourceImage;
	
	if ([self largeThumbnailFilePath])
		return self.largeThumbnailImage;
	
	if ([self thumbnailFilePath])
		return self.thumbnailImage;
		
	return nil;

}


# pragma mark - Trivial Stuff

+ (dispatch_queue_t) sharedResourceHandlingQueue {

  static dispatch_queue_t queue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      queue = dispatch_queue_create("com.waveface.wammer.WAFile.resourceHandlingQueue", DISPATCH_QUEUE_SERIAL);
  });
  
  return queue;

}

+ (NSSet *) keyPathsForValuesAffectingResourceImage {

	return [NSSet setWithObjects:
		kWAFileResourceFilePath,
		kWAFileResourceURL,
	nil];

}

- (UIImage *) resourceImage {

	NSString *resourceFilePath = self.resourceFilePath;
	if (!resourceFilePath)
		return nil;
	
	UIImage *resourceImage = objc_getAssociatedObject(self, &kWAFileResourceImage);
	if (![resourceImage.irRepresentedObject isEqualToString:resourceFilePath]) {
		resourceImage = [UIImage imageWithContentsOfFile:resourceFilePath];
		resourceImage.irRepresentedObject = resourceFilePath;
		objc_setAssociatedObject(self, &kWAFileResourceImage, resourceImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return resourceImage;
	
}

//- (void) setResourceImage:(UIImage *)newResourceImage {
//
//	if (objc_getAssociatedObject(self, &kWAFileResourceImage) == newResourceImage)
//		return;
//		
//	[self willChangeValueForKey:kWAFileResourceImage];
//	objc_setAssociatedObject(self, &kWAFileResourceImage, newResourceImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//	[self didChangeValueForKey:kWAFileResourceImage];
//
//}

- (UIImage *) thumbnailImage {
	
	UIImage *thumbnailImage = objc_getAssociatedObject(self, &kWAFileThumbnailImage);
	if (thumbnailImage)
		return thumbnailImage;
	
	NSString *thumbnailFilePath = self.thumbnailFilePath;
	if (!thumbnailFilePath)
		return nil;
	
	[self willChangeValueForKey:kWAFileThumbnailImage];
	thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailFilePath];
	thumbnailImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
	self.thumbnailImage = thumbnailImage;
	[self didChangeValueForKey:kWAFileThumbnailImage];
	
	return thumbnailImage;
	
}

- (void) setThumbnailImage:(UIImage *)newThumbnailImage {

	if (objc_getAssociatedObject(self, &kWAFileThumbnailImage) == newThumbnailImage)
		return;
	
	[self willChangeValueForKey:kWAFileThumbnailImage];
	objc_setAssociatedObject(self, &kWAFileThumbnailImage, newThumbnailImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self didChangeValueForKey:kWAFileThumbnailImage];

}

- (UIImage *) largeThumbnailImage {
	
	UIImage *largeThumbnailImage = objc_getAssociatedObject(self, &kWAFileLargeThumbnailImage);
	if (largeThumbnailImage)
		return largeThumbnailImage;
		
	NSString *largeThumbnailFilePath = self.largeThumbnailFilePath;
	if (!largeThumbnailFilePath)
		return nil;
    
	[self willChangeValueForKey:kWAFileLargeThumbnailImage];
	largeThumbnailImage = [UIImage imageWithContentsOfFile:largeThumbnailFilePath];
	largeThumbnailImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
	self.largeThumbnailImage = largeThumbnailImage;
	[self didChangeValueForKey:kWAFileLargeThumbnailImage];
	
	return largeThumbnailImage;
	
}

- (void) setLargeThumbnailImage:(UIImage *)newLargeThumbnailImage {

	if (objc_getAssociatedObject(self, &kWAFileLargeThumbnailImage) == newLargeThumbnailImage)
		return;
	
	[self willChangeValueForKey:kWAFileLargeThumbnailImage];
	objc_setAssociatedObject(self, &kWAFileLargeThumbnailImage, newLargeThumbnailImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self didChangeValueForKey:kWAFileLargeThumbnailImage];

}

- (BOOL) validatesResourceImage {

	return [objc_getAssociatedObject(self, &kWAFileValidatesResourceImage) boolValue];

}

- (void) setValidatesResourceImage:(BOOL)newFlag {

	if (self.validateResourceImage == newFlag)
		return;
	
	[self willChangeValueForKey:kWAFileValidatesResourceImage];
	objc_setAssociatedObject(self, &kWAFileValidatesResourceImage, [NSNumber numberWithBool:newFlag], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self didChangeValueForKey:kWAFileValidatesResourceImage];

}

- (BOOL) validatesThumbnailImage {

	return [objc_getAssociatedObject(self, &kWAFileValidatesThumbnailImage) boolValue];

}

- (void) setValidatesThumbnailImage:(BOOL)newFlag {

	if (self.validateThumbnailImage == newFlag)
		return;
	
	[self willChangeValueForKey:kWAFileValidatesThumbnailImage];
	objc_setAssociatedObject(self, &kWAFileValidatesThumbnailImage, [NSNumber numberWithBool:newFlag], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self didChangeValueForKey:kWAFileValidatesThumbnailImage];

}

- (BOOL) validatesLargeThumbnailImage {

	return [objc_getAssociatedObject(self, &kWAFileValidatesLargeThumbnailImage) boolValue];

}

- (void) setValidatesLargeThumbnailImage:(BOOL)newFlag {

	if (self.validateLargeThumbnailImage == newFlag)
		return;
	
	[self willChangeValueForKey:kWAFileValidatesLargeThumbnailImage];
	objc_setAssociatedObject(self, &kWAFileValidatesLargeThumbnailImage, [NSNumber numberWithBool:newFlag], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self didChangeValueForKey:kWAFileValidatesLargeThumbnailImage];

}


# pragma mark - Deprecated

- (UIImage *) thumbnail {

	UIImage *primitiveThumbnail = [self primitiveValueForKey:@"thumbnail"];
	
	if (primitiveThumbnail)
		return primitiveThumbnail;
	
	if (!self.resourceImage)
		return nil;
	
	primitiveThumbnail = [self.resourceImage irScaledImageWithSize:IRCGSizeGetCenteredInRect(self.resourceImage.size, (CGRect){ CGPointZero, (CGSize){ 128, 128 } }, 0.0f, YES).size];
	[self setPrimitiveValue:primitiveThumbnail forKey:@"thumbnail"];
	
	return self.thumbnail;

}

@end
