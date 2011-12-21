//
//  WAFile.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAFile.h"
#import "WAArticle.h"
#import "WAUser.h"
#import "WADataStore.h"
#import "UIImage+IRAdditions.h"
#import "CGGeometry+IRAdditions.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIDevice.h>
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif


@interface WAFile ()

+ (dispatch_queue_t) sharedResourceHandlingQueue;

@end

@implementation WAFile

@dynamic codeName;
@dynamic creationDeviceIdentifier;
@dynamic identifier;
@dynamic remoteFileName;
@dynamic remoteFileSize;
@dynamic remoteRepresentedImage;
@dynamic remoteResourceHash;
@dynamic remoteResourceType;
@dynamic resourceFilePath;
@dynamic resourceType;
@dynamic resourceURL;
@dynamic text;
@dynamic thumbnail;
@dynamic thumbnailFilePath;
@dynamic thumbnailURL;
@dynamic timestamp;
@dynamic article;
@dynamic owner;
@dynamic title;
@dynamic pageElements;
@dynamic pageElementOrder;

@synthesize resourceImage, thumbnailImage;

+ (dispatch_queue_t) sharedResourceHandlingQueue {

  static dispatch_queue_t queue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      queue = dispatch_queue_create("come.waveface.wammer.WAFile.resourceHandlingQueue", DISPATCH_QUEUE_SERIAL);
  });
  
  return queue;

}

- (void) dealloc { 

	[resourceImage release];
	[thumbnailImage release];
	[super dealloc];

}

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
	
	if (![resourceURL isFileURL]) {
		
		NSURL *ownURL = [[self objectID] URIRepresentation];
    NSString *preferredExtension = nil;
    
    if (self.resourceType) {
    
      preferredExtension = (NSString *)UTTypeCopyPreferredTagWithClass((CFStringRef)self.resourceType, kUTTagClassFilenameExtension);
      [[preferredExtension retain] autorelease];
      
      if (preferredExtension)
        CFRelease((CFStringRef)preferredExtension);
      
    }
      
		[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:resourceURL usingPriority:NSOperationQueuePriorityLow forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
			
			if (!tempFileURLOrNil)
				return;
      
      dispatch_async([[self class] sharedResourceHandlingQueue], ^{

        NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        WAFile *foundFile = (WAFile *)[context irManagedObjectForURI:ownURL];
        NSString *foundResourceFilePath = [foundFile primitiveValueForKey:@"resourceFilePath"];
        if (foundResourceFilePath || ![foundFile.resourceURL isEqualToString:[resourceURL absoluteString]])
          return;
        
        [foundFile.article willChangeValueForKey:@"fileOrder"];
        
        NSURL *fileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:tempFileURLOrNil];
        
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
        [foundFile.article didChangeValueForKey:@"fileOrder"];
        
        NSError *savingError = nil;
        BOOL didSave = [context save:&savingError];
        if (!didSave) {
          NSLog(@"Error saving: %@", savingError);
          NSParameterAssert(didSave);
        }
        
      });
      
		}];
		
		return nil;

	}
	
	primitivePath = [resourceURL path];
	
	if (primitivePath) {
		[self willChangeValueForKey:@"resourceFilePath"];
		[self willChangeValueForKey:@"resourceImage"];
		[self willChangeValueForKey:@"thumbnail"];
		[self setPrimitiveValue:primitivePath forKey:@"resourceFilePath"];
		[self didChangeValueForKey:@"resourceFilePath"];
		[self didChangeValueForKey:@"resourceImage"];
		[self didChangeValueForKey:@"thumbnail"];
	}
	
	return primitivePath;

}

- (NSString *) thumbnailFilePath {

	NSString *primitivePath = [self primitiveValueForKey:@"thumbnailFilePath"];
	
	if (primitivePath)
		return primitivePath;
	
	if (!self.thumbnailURL)
		return nil;
	
	NSURL *thumbnailURL = [NSURL URLWithString:self.thumbnailURL];
	
	if (![thumbnailURL isFileURL]) {
		
		NSURL *ownURL = [[self objectID] URIRepresentation];
		
		[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:thumbnailURL usingPriority:NSOperationQueuePriorityHigh forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
			
			if (!tempFileURLOrNil)
				return;
			
      dispatch_async([[self class] sharedResourceHandlingQueue], ^{

        NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        WAFile *foundFile = (WAFile *)[context irManagedObjectForURI:ownURL];
        NSString *foundThumbnailFilePath = [foundFile primitiveValueForKey:@"thumbnailFilePath"];
        if (foundThumbnailFilePath || ![foundFile.thumbnailURL isEqualToString:[thumbnailURL absoluteString]])
          return;
        
        [foundFile.article willChangeValueForKey:@"fileOrder"];
        foundFile.thumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForFileAtURL:tempFileURLOrNil] path];
        [foundFile.article didChangeValueForKey:@"fileOrder"];
        
        NSError *savingError = nil;
        if (![context save:&savingError])
          NSLog(@"Error saving: %@", savingError);
        
      });
			
		}];
		
		return nil;
		
	} else {
		
		primitivePath = [thumbnailURL path];
	
	}
	
	if (primitivePath) {
		[self willChangeValueForKey:@"thumbnailFilePath"];
		[self setPrimitiveValue:primitivePath forKey:@"thumbnailFilePath"];
		[self didChangeValueForKey:@"thumbnailFilePath"];
	}
	
	return primitivePath;

}

- (UIImage *) thumbnail {

	UIImage *primitiveThumbnail = [self primitiveValueForKey:@"thumbnail"];
	
	if (primitiveThumbnail)
		return primitiveThumbnail;
	
	if (!self.resourceImage)
		return nil;
	
	primitiveThumbnail = [self.resourceImage irScaledImageWithSize:IRCGSizeGetCenteredInRect(resourceImage.size, (CGRect){ CGPointZero, (CGSize){ 128, 128 } }, 0.0f, YES).size];
	[self setPrimitiveValue:primitiveThumbnail forKey:@"thumbnail"];
	
	return self.thumbnail;

}

- (UIImage *) resourceImage {
	
	if (resourceImage)
		return resourceImage;
	
	NSString *resourceFilePath = self.resourceFilePath;

	if (!resourceFilePath)
		return nil;
  
  UIImage *prospectiveResourceImage = [UIImage imageWithContentsOfFile:resourceFilePath];
  
  if (prospectiveResourceImage) {
	
    [self willChangeValueForKey:@"resourceImage"];
    resourceImage = [prospectiveResourceImage retain];
    resourceImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
    [self didChangeValueForKey:@"resourceImage"];

  } else {
  
    //  RESOURCE image is bad
  
  
  }
	
//	if (self.resourceURL && !resourceImage)
//	if (![[NSURL URLWithString:self.resourceURL] isFileURL])
//	if (resourceFilePath) {
//			
//		NSURL *ownURL = [[self objectID] URIRepresentation];
//		NSString *capturedResourceFileURL = self.resourceURL;
//		NSString *capturedResourceFilePath = resourceFilePath;
//    
//    dispatch_async([[self class] sharedResourceHandlingQueue], ^{
//		
//			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
//			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
//			
//			WAFile *foundFile = (WAFile *)[context irManagedObjectForURI:ownURL];
//			if (!foundFile)
//				return;
//			
//			NSString *resourceFilePath = [foundFile primitiveValueForKey:@"resourceFilePath"];
//			
//			if (![foundFile.resourceURL isEqualToString:capturedResourceFileURL])
//				return;
//				
//			if (![resourceFilePath isEqualToString:capturedResourceFilePath])
//				return;
//			
//			[[NSFileManager defaultManager] removeItemAtPath:resourceFilePath error:nil];
//			foundFile.resourceFilePath = nil;
//			
//			NSError *savingError = nil;
//			if (![context save:&savingError]) {
//				NSLog(@"Error saving: %@", savingError);
//				return;
//			}
//		
//		});
//
//	}
	
	return resourceImage;
	
}

- (UIImage *) thumbnailImage {
	
	if (thumbnailImage)
		return thumbnailImage;
		
	NSString *thumbnailFilePath = self.thumbnailFilePath;

	if (!thumbnailFilePath)
		return nil;
    
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.thumbnailFilePath]) {
	
		NSLog(@"%@ has invalid thumbnail file path", self);
		self.thumbnailFilePath = nil;
	
	}
  
	[self willChangeValueForKey:@"thumbnailImage"];
	thumbnailImage = [[UIImage imageWithContentsOfFile:thumbnailFilePath] retain];
	thumbnailImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
	[self didChangeValueForKey:@"thumbnailImage"];
	
	if (self.thumbnailURL && !thumbnailImage)
	if (![[NSURL URLWithString:self.thumbnailURL] isFileURL])
	if (thumbnailFilePath) {
	
		//	The loaded image is bad.
		
		NSURL *ownURL = [[self objectID] URIRepresentation];
		NSString *capturedThumbnailFileURL = self.thumbnailURL;
		NSString *capturedThumbnailFilePath = thumbnailFilePath;
		
    dispatch_async([[self class] sharedResourceHandlingQueue], ^{
		
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAFile *foundFile = (WAFile *)[context irManagedObjectForURI:ownURL];
			if (!foundFile)
				return;
			
			NSString *thumbnailFilePath = [foundFile primitiveValueForKey:@"thumbnailFilePath"];
			
			if (![foundFile.thumbnailURL isEqualToString:capturedThumbnailFileURL])
				return;
				
			if (![thumbnailFilePath isEqualToString:capturedThumbnailFilePath])
				return;
			
			foundFile.thumbnailFilePath = nil;
			
			NSError *savingError = nil;
			if (![context save:&savingError]) {
				NSLog(@"Error saving: %@", savingError);
				return;
			}
			
			[[NSFileManager defaultManager] removeItemAtPath:thumbnailFilePath error:nil];
			
		});
		
	}

	return thumbnailImage;
	
}

@end
