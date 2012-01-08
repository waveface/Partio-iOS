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


NSString * const kWAFileResourceImage = @"resourceImage";
NSString * const kWAFileResourceURL = @"resourceURL";
NSString * const kWAFileResourceFilePath = @"resourceFilePath";
NSString * const kWAFileThumbnailImage = @"thumbnailImage";
NSString * const kWAFileThumbnailURL = @"thumbnailURL";
NSString * const kWAFileThumbnailFilePath = @"thumbnailFilePath";
NSString * const kWAFileValidatesResourceImage = @"validatesResourceImage";
NSString * const kWAFileValidatesThumbnailImage = @"validatesThumbnailImage";
NSString * const kWAFilePresentableImage = @"presentableImage";


@implementation WAFile (WAAdditions)

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

- (BOOL) canScheduleBlobRetrieval {

	if ([[self objectID] isTemporaryID])
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
	NSString *ownResourceType = self.resourceType;
	
	NSURL *resourceURL = [NSURL URLWithString:self.resourceURL];
	
	if ([[self objectID] isTemporaryID])
		return;

	[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:resourceURL usingPriority:NSOperationQueuePriorityLow forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
		
		if (!tempFileURLOrNil)
			return;
		
		dispatch_async([[self class] sharedResourceHandlingQueue], ^{

			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAFile *foundFile = (WAFile *)[context irManagedObjectForURI:ownURL];

			@try {
			
				NSString *foundResourceFilePath = [foundFile primitiveValueForKey:@"resourceFilePath"];
				if (foundResourceFilePath || ![foundFile.resourceURL isEqualToString:[resourceURL absoluteString]])
					return;
			
			} @catch (NSException *exception) {
			
				NSLog(@"inaccessible %@", exception);
				return;
				
			}
			
			// [foundFile.article willChangeValueForKey:@"fileOrder"];
			
			NSURL *fileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:tempFileURLOrNil];
			
			NSString *preferredExtension = nil;
			if (ownResourceType)
				preferredExtension = [NSMakeCollectable(UTTypeCopyPreferredTagWithClass((CFStringRef)ownResourceType, kUTTagClassFilenameExtension)) autorelease];
			
			if (preferredExtension) {
				
				NSURL *newFileURL = [NSURL fileURLWithPath:[[[fileURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:preferredExtension]];
				NSError *movingError = nil;
				
				if (![[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:newFileURL error:&movingError]) {
					
					NSLog(@"Error moving to new URL: %@", movingError);
					
				} else {
				
					fileURL = newFileURL;
				
				}
				
			}
			
			foundFile.resourceFilePath = [fileURL path];
			// [foundFile.article didChangeValueForKey:@"fileOrder"];
			
			NSError *savingError = nil;
			BOOL didSave = [context save:&savingError];
			if (!didSave) {
				NSLog(@"Error saving: %@", savingError);
				NSParameterAssert(didSave);
			}
			
		});
		
	}];
		
}

- (void) setResourceFilePath:(NSString *)newResourceFilePath {

	NSLog(@"%s %@", __PRETTY_FUNCTION__, newResourceFilePath);
	
	[self willChangeValueForKey:@"thumbnailFilePath"];
	
	[self setPrimitiveResourceFilePath:newResourceFilePath];
	[self setResourceImage:nil];
	[self setValidatesResourceImage:!!newResourceFilePath];
	[self updatePresentableImage];
	
	[self didChangeValueForKey:@"thumbnailFilePath"];
	
}

- (void) setThumbnailFilePath:(NSString *)newThumbnailFilePath {
	
	NSLog(@"%s %@", __PRETTY_FUNCTION__, newThumbnailFilePath);

	[self willChangeValueForKey:@"thumbnailFilePath"];
	
	[self setPrimitiveThumbnailFilePath:newThumbnailFilePath];
	[self setThumbnailImage:nil];
	[self setValidatesThumbnailImage:!!newThumbnailFilePath];
	[self updatePresentableImage];
	
	[self didChangeValueForKey:@"thumbnailFilePath"];
	
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
		
	NSURL *ownURL = [[self objectID] URIRepresentation];
	
	if ([[self objectID] isTemporaryID])
		return nil;
	
	[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:thumbnailURL usingPriority:NSOperationQueuePriorityHigh forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
		
		if (!tempFileURLOrNil)
			return;
		
		dispatch_async([[self class] sharedResourceHandlingQueue], ^{

			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAFile *foundFile = (WAFile *)[context irManagedObjectForURI:ownURL];
			
			@try {
			
				NSString *foundThumbnailFilePath = [foundFile primitiveValueForKey:@"thumbnailFilePath"];
				if (foundThumbnailFilePath || ![foundFile.thumbnailURL isEqualToString:[thumbnailURL absoluteString]])
					return;
			
			} @catch (NSException *exception) {
			
				NSLog(@"inaccessible %@", exception);
				return;
				
			}
			
			// [foundFile.article willChangeValueForKey:@"fileOrder"];
			foundFile.thumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForFileAtURL:tempFileURLOrNil] path];
			// [foundFile.article didChangeValueForKey:@"fileOrder"];
			
			NSError *savingError = nil;
			if (![context save:&savingError])
				NSLog(@"Error saving: %@", savingError);
			
		});
		
	}];
	
	return nil;

}

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

- (BOOL) validateForDelete:(NSError **)error {

	if (![super validateForDelete:error])
		return NO;
	
	if (![self validateThumbnailImageIfNeeded:error])
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
	
	if (![self validateResourceImageIfNeeded:error])
		return NO;

	return YES;

}

- (BOOL) validateForUpdate:(NSError **)error {

	if (![super validateForUpdate:error])
		return NO;
	
	if (![self validateThumbnailImageIfNeeded:error])
		return NO;
	
	if (![self validateResourceImageIfNeeded:error])
		return NO;

	return YES;

}

- (void) prepareForDeletion {

	[super prepareForDeletion];
	
	NSString *thumbnailPath = [self primitiveValueForKey:@"thumbnailFilePath"];
	NSString *resourcePath = [self primitiveValueForKey:@"resourceFilePath"];
	
	if (thumbnailPath)
		[[NSFileManager defaultManager] removeItemAtPath:thumbnailPath error:nil];

	if (resourcePath)
		[[NSFileManager defaultManager] removeItemAtPath:resourcePath error:nil];
	
}

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


# pragma mark - Presentable Image & KVO

- (UIImage *) presentableImage {

	UIImage *presentableImage = objc_getAssociatedObject(self, &kWAFilePresentableImage);
	if (presentableImage)
		return presentableImage;
	
	return [self updatePresentableImage];

}

- (UIImage *) updatePresentableImage {

	UIImage *oldPresentableImage = objc_getAssociatedObject(self, &kWAFilePresentableImage);
	UIImage *newPresentableImage = oldPresentableImage;
	
	if (self.resourceImage) {
		newPresentableImage = self.resourceImage;
	} else if (self.thumbnailImage) {
		newPresentableImage = self.thumbnailImage;
	}
	
	if (oldPresentableImage != newPresentableImage) {
		[self willChangeValueForKey:kWAFilePresentableImage];
		objc_setAssociatedObject(self, &kWAFilePresentableImage, newPresentableImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[self didChangeValueForKey:kWAFilePresentableImage];
	}
	
	NSLog(@"%s: Old %@, New %@", __PRETTY_FUNCTION__, oldPresentableImage, newPresentableImage);

	return newPresentableImage;

}


# pragma mark - Trivial Stuff

+ (dispatch_queue_t) sharedResourceHandlingQueue {

  static dispatch_queue_t queue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      queue = dispatch_queue_create("come.waveface.wammer.WAFile.resourceHandlingQueue", DISPATCH_QUEUE_SERIAL);
  });
  
  return queue;

}

- (UIImage *) resourceImage {
	
	UIImage *resourceImage = objc_getAssociatedObject(self, &kWAFileResourceImage);
	if (resourceImage)
		return resourceImage;
	
	NSString *resourceFilePath = self.resourceFilePath;
	if (!resourceFilePath)
		return nil;
  
	[self willChangeValueForKey:kWAFileResourceImage];
	resourceImage = [[UIImage imageWithContentsOfFile:resourceFilePath] retain];
	resourceImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
	self.resourceImage = resourceImage;
	[self didChangeValueForKey:kWAFileResourceImage];
	
	return resourceImage;
	
}

- (void) setResourceImage:(UIImage *)newResourceImage {

	if (objc_getAssociatedObject(self, &kWAFileResourceImage) == newResourceImage)
		return;
		
	[self willChangeValueForKey:kWAFileResourceImage];
	objc_setAssociatedObject(self, &kWAFileResourceImage, newResourceImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self didChangeValueForKey:kWAFileResourceImage];

}

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

@end
