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


@interface WAFile (CoreDataGeneratedPrimitiveAccessors)

- (void) setPrimitiveResourceFilePath:(NSString *)newResourceFilePath;
- (NSString *) primitiveResourceFilePath;

- (void) setPrimitiveResourceURL:(NSString *)newResourceURL;
- (NSString *) primitiveResourceURL;

- (void) setPrimitiveThumbnailFilePath:(NSString *)newThumbnailFilePath;
- (NSString *) primitiveThumbnailFilePath;

- (void) setPrimitiveThumbnailURL:(NSString *)newThumbnailURL;
- (NSString *) primitiveThumbnailURL;

- (void) setPrimitiveLargeThumbnailFilePath:(NSString *)newLargeThumbnailFilePath;
- (NSString *) primitiveLargeThumbnailFilePath;

- (void) setPrimitiveLargeThumbnailURL:(NSString *)newLargeThumbnailURL;
- (NSString *) primitiveLargeThumbnailURL;

@end


@interface WAFile (WAAdditions_Accessors)

@property (nonatomic, readwrite, retain) UIImage *resourceImage;
@property (nonatomic, readwrite, retain) UIImage *largeThumbnailImage;
@property (nonatomic, readwrite, retain) UIImage *thumbnailImage;

- (void) associateObject:(id)anObject usingKey:(const void *)aKey associationPolicy:(objc_AssociationPolicy)policy notify:(BOOL)emitsChangeNotifications usingKey:(NSString *)propertyKey;

@end


@interface WAFile (WAAdditions_Validators)

@property (nonatomic, readwrite, assign) BOOL validatesResourceImage;
@property (nonatomic, readwrite, assign) BOOL validatesLargeThumbnailImage;
@property (nonatomic, readwrite, assign) BOOL validatesThumbnailImage;

- (BOOL) validateResourceImageIfNeeded:(NSError **)outError;
- (BOOL) validateResourceImage:(NSError **)outError;
- (BOOL) validateLargeThumbnailImageIfNeeded:(NSError **)outError;
- (BOOL) validateLargeThumbnailImage:(NSError **)outError;
- (BOOL) validateThumbnailImageIfNeeded:(NSError **)outError;
- (BOOL) validateThumbnailImage:(NSError **)outError;

+ (BOOL) validateImageAtPath:(NSString *)aFilePath error:(NSError **)outError;

@end


@interface WAFile (WAAdditions_RemoteBlobRetrieval)

- (void) scheduleResourceRetrievalIfPermitted;
- (void) scheduleThumbnailRetrievalIfPermitted;
- (void) scheduleLargeThumbnailRetrievalIfPermitted;

- (BOOL) canScheduleBlobRetrieval;
- (BOOL) canScheduleExpensiveBlobRetrieval;

- (void) scheduleRetrievalForBlobURL:(NSURL *)blobURL blobKeyPath:(NSString *)blobURLKeyPath filePathKeyPath:(NSString *)filePathKeyPath usingPriority:(NSOperationQueuePriority)priority;

- (BOOL) takeBlobFromTemporaryFile:(NSString *)aPath forKeyPath:(NSString *)fileKeyPath matchingURL:(NSURL *)anURL forKeyPath:(NSString *)urlKeyPath;

@end


@implementation WAFile (WAAdditions)

- (id) initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context {

	self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
	if (!self)
		return nil;
	
	self.validatesThumbnailImage = YES;
	self.validatesLargeThumbnailImage = YES;
	self.validatesResourceImage = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	
	return self;

}

- (void) handleDidReceiveMemoryWarning:(NSNotification *)aNotification {

	[self associateObject:nil usingKey:&kWAFileThumbnailImage associationPolicy:OBJC_ASSOCIATION_ASSIGN notify:YES usingKey:kWAFileThumbnailImage];
	[self associateObject:nil usingKey:&kWAFileLargeThumbnailImage associationPolicy:OBJC_ASSOCIATION_ASSIGN notify:YES usingKey:kWAFileLargeThumbnailImage];
	[self associateObject:nil usingKey:&kWAFileResourceImage associationPolicy:OBJC_ASSOCIATION_ASSIGN notify:YES usingKey:kWAFileResourceImage];

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];

}


# pragma mark - Lifecycle

- (void) awakeFromFetch {

  [super awakeFromFetch];
  
  [self irReconcileObjectOrderWithKey:@"pageElements" usingArrayKeyed:@"pageElementOrder"];
	
	//	TBD: We’re assuming that everthing is restorable, might not be true if users pound on local drafts more
	
	NSFileManager * const fileManager = [NSFileManager defaultManager];	
	
	if (![self validateThumbnailImage:nil]) {
		[fileManager removeItemAtPath:self.thumbnailFilePath error:nil];
		self.thumbnailFilePath = nil;
	}
	
	if (![self validateLargeThumbnailImage:nil]) {
		[fileManager removeItemAtPath:self.largeThumbnailFilePath error:nil];
		self.largeThumbnailFilePath = nil;
	}
		
	if (![self validateResourceImage:nil]) {
		[fileManager removeItemAtPath:self.resourceFilePath error:nil];
		self.resourceFilePath = nil;
	}
	
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

	if (![[self objectID] isTemporaryID])
	if (![self isDeleted])
		return YES;
	
	return NO;

}

- (BOOL) canScheduleExpensiveBlobRetrieval {

	if ([self canScheduleBlobRetrieval])
	if (![[WARemoteInterface sharedInterface] areExpensiveOperationsAllowed])
		return YES;
	
	return NO;
	
}

- (void) scheduleResourceRetrievalIfPermitted {

	if (![self canScheduleExpensiveBlobRetrieval])
		return;

	[self scheduleRetrievalForBlobURL:[NSURL URLWithString:self.resourceURL] blobKeyPath:kWAFileResourceURL filePathKeyPath:kWAFileResourceFilePath usingPriority:NSOperationQueuePriorityLow];

}

- (void) scheduleThumbnailRetrievalIfPermitted {

	if (![self canScheduleBlobRetrieval])
		return;
	
	[self scheduleRetrievalForBlobURL:[NSURL URLWithString:self.thumbnailURL] blobKeyPath:kWAFileThumbnailURL filePathKeyPath:kWAFileThumbnailFilePath usingPriority:NSOperationQueuePriorityHigh];

}

- (void) scheduleLargeThumbnailRetrievalIfPermitted {

	if (![self canScheduleBlobRetrieval])
		return;
	
	[self scheduleRetrievalForBlobURL:[NSURL URLWithString:self.largeThumbnailURL] blobKeyPath:kWAFileLargeThumbnailURL filePathKeyPath:kWAFileLargeThumbnailFilePath usingPriority:NSOperationQueuePriorityNormal];
		
}

- (void) scheduleRetrievalForBlobURL:(NSURL *)blobURL blobKeyPath:(NSString *)blobURLKeyPath filePathKeyPath:(NSString *)filePathKeyPath usingPriority:(NSOperationQueuePriority)priority {

	NSURL *ownURL = [[self objectID] URIRepresentation];
	
	[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:blobURL usingPriority:priority forced:NO withCompletionBlock:^(NSURL *tempFileURLOrNil) {
		
		dispatch_async([[self class] sharedResourceHandlingQueue], ^ {

			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
			
			if ([file takeBlobFromTemporaryFile:[tempFileURLOrNil path] forKeyPath:filePathKeyPath matchingURL:blobURL forKeyPath:blobURLKeyPath]) {
			
				context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
				NSError *savingError = nil;
				if (![context save:&savingError])
					NSLog(@"Error saving: %@", savingError);

			}
			
		});
		
	}];

}

- (BOOL) takeBlobFromTemporaryFile:(NSString *)aPath forKeyPath:(NSString *)fileKeyPath matchingURL:(NSURL *)anURL forKeyPath:(NSString *)urlKeyPath {

	@try {
		[self primitiveValueForKey:[(NSPropertyDescription *)[[self.entity properties] lastObject] name]];
	} @catch (NSException *exception) {
		NSLog(@"Got access exception: %@", exception);
	}

	NSString *currentFilePath = [self valueForKey:fileKeyPath];
	if (currentFilePath || ![[self valueForKey:urlKeyPath] isEqualToString:[anURL absoluteString]]) {
		//	NSLog(@"Skipping double-writing");
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

- (NSString *) relativePathFromPath:(NSString *)absolutePath {

	WADataStore *const dataStore = [WADataStore defaultStore];
	return [dataStore relativePathWithBasePath:[dataStore persistentFileURLBasePath] filePath:absolutePath];

}

- (NSString *) absolutePathFromPath:(NSString *)relativePath {

	WADataStore *const dataStore = [WADataStore defaultStore];
	return [dataStore absolutePathWithBasePath:[dataStore persistentFileURLBasePath] filePath:relativePath];

}

- (void) setResourceFilePath:(NSString *)newResourceFilePath {

	[self willChangeValueForKey:kWAFileResourceFilePath];
	
	[self setPrimitiveResourceFilePath:[self relativePathFromPath:newResourceFilePath]];
	[self setResourceImage:nil];
	[self setValidatesResourceImage:!!newResourceFilePath];
	
	[self didChangeValueForKey:kWAFileResourceFilePath];
	
}

- (void) setThumbnailFilePath:(NSString *)newThumbnailFilePath {
	
	[self willChangeValueForKey:kWAFileThumbnailFilePath];
	
	[self setPrimitiveThumbnailFilePath:[self relativePathFromPath:newThumbnailFilePath]];
	[self setThumbnailImage:nil];
	[self setValidatesThumbnailImage:!!newThumbnailFilePath];
	
	[self didChangeValueForKey:kWAFileThumbnailFilePath];
	
}

- (void) setLargeThumbnailFilePath:(NSString *)newLargeThumbnailFilePath {
	
	[self willChangeValueForKey:kWAFileLargeThumbnailFilePath];
	
	[self setPrimitiveLargeThumbnailFilePath:[self relativePathFromPath:newLargeThumbnailFilePath]];
	[self setLargeThumbnailImage:nil];
	[self setValidatesLargeThumbnailImage:!!newLargeThumbnailFilePath];
	
	[self didChangeValueForKey:kWAFileLargeThumbnailFilePath];
	
}

- (NSString *) resourceFilePath {

	NSString *primitivePath = [self primitiveValueForKey:@"resourceFilePath"];
	
	if (primitivePath)
		return [self absolutePathFromPath:primitivePath];
	
	if (!self.resourceURL)
		return nil;
	
	NSURL *resourceURL = [NSURL URLWithString:self.resourceURL];
	if (!resourceURL)
		return nil;

	if ([resourceURL isFileURL])
		return [resourceURL path];
	
	[self scheduleResourceRetrievalIfPermitted];
	
	return nil;

}

- (NSString *) thumbnailFilePath {

	NSString *primitivePath = [self primitiveValueForKey:@"thumbnailFilePath"];
	
	if (primitivePath)
		return [self absolutePathFromPath:primitivePath];
	
	if (!self.thumbnailURL)
		return nil;
	
	NSURL *thumbnailURL = [NSURL URLWithString:self.thumbnailURL];
	if (!thumbnailURL)
		return nil;
	
	if ([thumbnailURL isFileURL])
		return primitivePath;
	
	[self scheduleThumbnailRetrievalIfPermitted];
	
	return nil;

}

- (NSString *) largeThumbnailFilePath {

	NSString *primitivePath = [self primitiveValueForKey:kWAFileLargeThumbnailFilePath];
	
	if (primitivePath)
		return [self absolutePathFromPath:primitivePath];
	
	if (!self.largeThumbnailURL)
		return nil;
	
	NSURL *largeThumbnailURL = [NSURL URLWithString:self.largeThumbnailURL];
	if (!largeThumbnailURL)
		return nil;
	
	if ([largeThumbnailURL isFileURL])
		return [largeThumbnailURL path];
	
	[self scheduleLargeThumbnailRetrievalIfPermitted];
	
	return nil;

}

- (BOOL) validateForDelete:(NSError **)error {

	if ([super validateForDelete:error])
	if ([self validateThumbnailImageIfNeeded:error])
	if ([self validateLargeThumbnailImageIfNeeded:error])
	if ([self validateResourceImageIfNeeded:error])
		return YES;
	
	return NO;

}

- (BOOL) validateForInsert:(NSError **)error {

	if ([super validateForInsert:error])
	if ([self validateThumbnailImageIfNeeded:error])
	if ([self validateLargeThumbnailImageIfNeeded:error])
	if ([self validateResourceImageIfNeeded:error])
		return YES;
	
	return NO;

}

- (BOOL) validateForUpdate:(NSError **)error {

	if ([super validateForUpdate:error])
	if ([self validateThumbnailImageIfNeeded:error])
	if ([self validateLargeThumbnailImageIfNeeded:error])
	if ([self validateResourceImageIfNeeded:error])
		return YES;
	
	return NO;

}

- (void) prepareForDeletion {

	[super prepareForDeletion];

#if 0
	
	//	TBD: Create IRFileWrapper for this, since deleting a file entity does NOT mean that there is no other entity using it
	//	FIXME: For now, we’re doing zero cleanup, and just leaving stuff there waiting for the next version to clean them up
	
	NSString *thumbnailPath, *largeThumbnailPath, *resourcePath;
	
	if ((thumbnailPath = [self primitiveValueForKey:kWAFileThumbnailFilePath]))
		[[NSFileManager defaultManager] removeItemAtPath:thumbnailPath error:nil];

	if ((largeThumbnailPath = [self primitiveValueForKey:kWAFileLargeThumbnailFilePath]))
		[[NSFileManager defaultManager] removeItemAtPath:largeThumbnailPath error:nil];
	
	if ((resourcePath = [self primitiveValueForKey:kWAFileResourceFilePath]))
		[[NSFileManager defaultManager] removeItemAtPath:resourcePath error:nil];
	
#endif
	
}


# pragma mark - Validation



# pragma mark Lazy Images

+ (NSSet *) keyPathsForValuesAffectingPresentableImage {

	return [NSSet setWithObjects:
		kWAFileThumbnailURL,
		kWAFileThumbnailFilePath,
		kWAFileLargeThumbnailURL,
		kWAFileLargeThumbnailFilePath,
		kWAFileResourceURL,
		kWAFileResourceFilePath,
	nil];

}

- (UIImage *) presentableImage {

	if ([self resourceFilePath])
	if (self.resourceImage)
		return self.resourceImage;
	
	if ([self largeThumbnailFilePath])
	if (self.largeThumbnailImage)
		return self.largeThumbnailImage;
	
	if ([self thumbnailFilePath])
	if (self.thumbnailImage)
		return self.thumbnailImage;
	
	return nil;

}

+ (NSSet *) keyPathsForValuesAffectingResourceImage {

	return [NSSet setWithObjects:
		kWAFileResourceFilePath,
		kWAFileResourceURL,
	nil];

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

- (UIImage *) resourceImage {

	UIImage *resourceImage = objc_getAssociatedObject(self, &kWAFileResourceImage);
	if (resourceImage)
		return resourceImage;
	
	NSString *resourceFilePath = self.resourceFilePath;
	if (!resourceFilePath)
		return nil;
	
	resourceImage = [UIImage imageWithContentsOfFile:resourceFilePath];
	resourceImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];

	[self associateObject:resourceImage usingKey:&kWAFileResourceImage associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC notify:NO usingKey:kWAFileResourceImage];
	
	return resourceImage;
	
}

- (void) setResourceImage:(UIImage *)newResourceImage {

	[self associateObject:newResourceImage usingKey:&kWAFileResourceImage associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC notify:YES usingKey:kWAFileResourceImage];

}

+ (NSSet *) keyPathsForValuesAffectingThumbnailImage {

	return [NSSet setWithObjects:
		kWAFileThumbnailFilePath,
		kWAFileThumbnailURL,
	nil];

}

- (UIImage *) thumbnailImage {
	
	UIImage *thumbnailImage = objc_getAssociatedObject(self, &kWAFileThumbnailImage);
	if (thumbnailImage)
		return thumbnailImage;
	
	NSString *thumbnailFilePath = self.thumbnailFilePath;
	if (!thumbnailFilePath)
		return nil;
	
	thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailFilePath];
	thumbnailImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
	
	[self associateObject:thumbnailImage usingKey:&kWAFileThumbnailImage associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC notify:NO usingKey:kWAFileThumbnailImage];
	
	return thumbnailImage;
	
}

- (void) setThumbnailImage:(UIImage *)newThumbnailImage {

	[self associateObject:newThumbnailImage usingKey:&kWAFileThumbnailImage associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC notify:YES usingKey:kWAFileThumbnailImage];

}

- (UIImage *) largeThumbnailImage {
	
	UIImage *largeThumbnailImage = objc_getAssociatedObject(self, &kWAFileLargeThumbnailImage);
	if (largeThumbnailImage)
		return largeThumbnailImage;
		
	NSString *largeThumbnailFilePath = self.largeThumbnailFilePath;
	if (!largeThumbnailFilePath)
		return nil;
	
	largeThumbnailImage = [UIImage imageWithContentsOfFile:largeThumbnailFilePath];
	largeThumbnailImage.irRepresentedObject = [NSValue valueWithNonretainedObject:self];
	
	[self associateObject:largeThumbnailImage usingKey:&kWAFileLargeThumbnailImage associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC notify:NO usingKey:kWAFileLargeThumbnailImage];
	
	return largeThumbnailImage;
	
}

- (void) setLargeThumbnailImage:(UIImage *)newLargeThumbnailImage {

	[self associateObject:newLargeThumbnailImage usingKey:&kWAFileLargeThumbnailImage associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC notify:YES usingKey:kWAFileLargeThumbnailImage];

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





@implementation WAFile (WAAdditions_Accessors)

@dynamic thumbnailImage, largeThumbnailImage, resourceImage;

- (void) associateObject:(id)anObject usingKey:(const void *)aKey associationPolicy:(objc_AssociationPolicy)policy notify:(BOOL)emitsChangeNotifications usingKey:(NSString *)propertyKey {

	if (objc_getAssociatedObject(self, aKey) == anObject)
		return;
	
	if (emitsChangeNotifications)
		[self willChangeValueForKey:propertyKey];
	
	objc_setAssociatedObject(self, aKey, anObject, policy);
	
	if (emitsChangeNotifications)
		[self didChangeValueForKey:propertyKey];

}

@end


@implementation WAFile (WAAdditions_Validators)

- (BOOL) validatesResourceImage {

	return [objc_getAssociatedObject(self, &kWAFileValidatesResourceImage) boolValue];

}

- (void) setValidatesResourceImage:(BOOL)newFlag {

	[self associateObject:(id)(newFlag ? kCFBooleanTrue : kCFBooleanFalse) usingKey:&kWAFileValidatesResourceImage associationPolicy:OBJC_ASSOCIATION_ASSIGN notify:YES usingKey:kWAFileValidatesResourceImage];

}

- (BOOL) validatesThumbnailImage {

	return [objc_getAssociatedObject(self, &kWAFileValidatesThumbnailImage) boolValue];
}

- (void) setValidatesThumbnailImage:(BOOL)newFlag {

	[self associateObject:(id)(newFlag ? kCFBooleanTrue : kCFBooleanFalse) usingKey:&kWAFileValidatesThumbnailImage associationPolicy:OBJC_ASSOCIATION_ASSIGN notify:YES usingKey:kWAFileValidatesThumbnailImage];
	
}

- (BOOL) validatesLargeThumbnailImage {

	return [objc_getAssociatedObject(self, &kWAFileValidatesLargeThumbnailImage) boolValue];
	
}

- (void) setValidatesLargeThumbnailImage:(BOOL)newFlag {

	[self associateObject:(id)(newFlag ? kCFBooleanTrue : kCFBooleanFalse) usingKey:&kWAFileValidatesLargeThumbnailImage associationPolicy:OBJC_ASSOCIATION_ASSIGN notify:YES usingKey:kWAFileValidatesLargeThumbnailImage];
	
}

- (BOOL) validateResourceImageIfNeeded:(NSError **)outError {
	
	return self.validatesResourceImage ? [self validateResourceImage:outError] : YES;
	
}

- (BOOL) validateResourceImage:(NSError **)outError {
	
	return [[self class] validateImageAtPath:[self valueForKey:kWAFileResourceFilePath] error:outError];
	
}

- (BOOL) validateThumbnailImageIfNeeded:(NSError **)outError {
	
	return self.validatesThumbnailImage ? [self validateThumbnailImage:outError] : YES;
	
}

- (BOOL) validateThumbnailImage:(NSError **)outError {
	
	return [[self class] validateImageAtPath:[self valueForKey:kWAFileThumbnailFilePath] error:outError];
	
}

- (BOOL) validateLargeThumbnailImageIfNeeded:(NSError **)outError {
	
	return self.validatesLargeThumbnailImage ? [self validateLargeThumbnailImage:outError] : YES;
	
}

- (BOOL) validateLargeThumbnailImage:(NSError **)outError {
	
	return [[self class] validateImageAtPath:[self valueForKey:kWAFileLargeThumbnailFilePath] error:outError];	
	
}

+ (BOOL) validateImageAtPath:(NSString *)aFilePath error:(NSError **)error {
	
	if (!aFilePath)
		return YES;

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

@end
