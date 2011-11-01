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


@implementation WAFile

@dynamic identifier;
@dynamic resourceFilePath;
@dynamic resourceType;
@dynamic resourceURL;
@dynamic text;
@dynamic thumbnailFilePath;
@dynamic thumbnailURL;
@dynamic timestamp;
@dynamic article;
@dynamic owner;
@dynamic thumbnail;

@synthesize resourceImage, thumbnailImage;

- (void) dealloc { 

	[resourceImage release];
	[thumbnailImage release];
	[super dealloc];

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
			@"identifier", @"id",
			@"text", @"text",
			@"thumbnailURL", @"thumbnail_url",
			@"resourceURL", @"url",
			@"resourceType", @"type",
			@"timestamp", @"timestamp",
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

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
	
		return returnedValue;
		
	}
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

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
		
		[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:resourceURL usingPriority:NSOperationQueuePriorityLow forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
			
			if (!tempFileURLOrNil)
				return;
					
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAFile *foundFile = (WAFile *)[context irManagedObjectForURI:ownURL];
			NSString *foundResourceFilePath = [foundFile primitiveValueForKey:@"resourceFilePath"];
			if (foundResourceFilePath || ![foundFile.resourceURL isEqualToString:[resourceURL absoluteString]])
				return;
				
			[foundFile.article willChangeValueForKey:@"fileOrder"];
			foundFile.resourceFilePath = [[[WADataStore defaultStore] persistentFileURLForFileAtURL:tempFileURLOrNil] path];
			[foundFile.article didChangeValueForKey:@"fileOrder"];
			
			NSError *savingError = nil;
			BOOL didSave = [context save:&savingError];
			if (!didSave) {
				NSLog(@"Error saving: %@", savingError);
				NSParameterAssert(didSave);
			}
			
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
			
		}];
		
		return nil;
		
	}
		
	primitivePath = [thumbnailURL path];
	
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
	
	[self willChangeValueForKey:@"resourceImage"];
	resourceImage = [[UIImage imageWithContentsOfFile:self.resourceFilePath] retain];
	resourceImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
	[self didChangeValueForKey:@"resourceImage"];
	
	if (self.resourceURL && !resourceImage)
	if (![[NSURL URLWithString:self.resourceURL] isFileURL])
	if (resourceFilePath) {
			
		NSURL *ownURL = [[self objectID] URIRepresentation];
		NSString *capturedResourceFileURL = self.resourceURL;
		NSString *capturedResourceFilePath = resourceFilePath;
		
		dispatch_async(dispatch_get_global_queue(0, 0), ^ {
		
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAFile *foundFile = (WAFile *)[context irManagedObjectForURI:ownURL];
			if (!foundFile)
				return;
			
			NSString *resourceFilePath = [foundFile primitiveValueForKey:@"resourceFilePath"];
			
			if (![foundFile.resourceURL isEqualToString:capturedResourceFileURL])
				return;
				
			if (![resourceFilePath isEqualToString:capturedResourceFilePath])
				return;
			
			[[NSFileManager defaultManager] removeItemAtPath:resourceFilePath error:nil];
			foundFile.resourceFilePath = nil;
			
			NSError *savingError = nil;
			if (![context save:&savingError]) {
				NSLog(@"Error saving: %@", savingError);
				return;
			}
		
		});

	}
	
	return resourceImage;
	
}

- (UIImage *) thumbnailImage {
	
	if (thumbnailImage)
		return thumbnailImage;
		
	NSString *thumbnailFilePath = self.thumbnailFilePath;

	if (!thumbnailFilePath)
		return nil;
		
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
		
		dispatch_async(dispatch_get_global_queue(0, 0), ^ {
		
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
			
			[[NSFileManager defaultManager] removeItemAtPath:thumbnailFilePath error:nil];
			foundFile.thumbnailFilePath = nil;
			
			NSError *savingError = nil;
			if (![context save:&savingError]) {
				NSLog(@"Error saving: %@", savingError);
				return;
			}
			
		});
		
	}

	return thumbnailImage;
	
}

@end
