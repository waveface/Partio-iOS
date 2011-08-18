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
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}





+ (IRRemoteResourcesManager *) sharedRemoteResourcesManager {

	static IRRemoteResourcesManager *sharedManager = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
    
		sharedManager = [[IRRemoteResourcesManager alloc] init];
		sharedManager.delegate = (id<IRRemoteResourcesManagerDelegate>)[UIApplication sharedApplication].delegate;
		
		id notificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:MLRemoteResourcesManagerDidRetrieveResourceNotification object:nil queue:[self remoteResourceHandlingQueue] usingBlock:^(NSNotification *aNotification) {
			
			NSURL *representingURL = (NSURL *)[aNotification object];
			NSData *resourceData = [sharedManager resourceAtRemoteURL:representingURL skippingUncachedFile:NO];
			
			if (![resourceData length])
			return;
						
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			NSArray *matchingObjects = [context executeFetchRequest:((^ {
				
				NSFetchRequest *fr = [[[NSFetchRequest alloc] init] autorelease];
				fr.entity = [WAFile entityDescriptionForContext:context];
				fr.predicate = [NSPredicate predicateWithFormat:@"resourceURL == %@", [representingURL absoluteString]];
				
				return fr;
			
			})()) error:nil];
			
			for (WAFile *matchingObject in matchingObjects)
				matchingObject.resourceFilePath = [[[WADataStore defaultStore] persistentFileURLForData:resourceData] path];
			
			[context save:nil];
			
		}];
		
		objc_setAssociatedObject(sharedManager, @"boundNotificationObject", notificationObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC); 

	});
	
	return sharedManager;

}

+ (NSOperationQueue *) remoteResourceHandlingQueue {

	static NSOperationQueue *returnedQueue = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		returnedQueue = [[NSOperationQueue alloc] init];
	});
	
	return returnedQueue;

}

- (NSString *) resourceFilePath {

	NSString *primitivePath = [self primitiveValueForKey:@"resourceFilePath"];
	
	if (primitivePath)
		return primitivePath;
	
	if (!self.resourceURL)
		return nil;
	
	NSURL *resourceURL = [NSURL URLWithString:self.resourceURL];
	
	if (![resourceURL isFileURL]) {
		[[[self class] sharedRemoteResourcesManager] retrieveResourceAtRemoteURL:resourceURL forceReload:YES];
		return nil;
	}
	
	primitivePath = [resourceURL path];
	
	if (primitivePath) {
		[self willChangeValueForKey:@"resourceFilePath"];
		[self setPrimitiveValue:primitivePath forKey:@"resourceFilePath"];
		[self didChangeValueForKey:@"resourceFilePath"];
	}
	
	return primitivePath;

}

@end
