//
//  WAOpenGraphElement.m
//  wammer-iOS
//
//  Created by Evadne Wu on 9/8/11.
//  Copyright (c) 2011 Waveface Inc. All rights reserved.
//

#import "WAOpenGraphElement.h"
#import "WADataStore.h"


@implementation WAOpenGraphElement

@dynamic providerName;
@dynamic providerURL;
@dynamic text;
@dynamic title;
@dynamic thumbnailFilePath;
@dynamic thumbnailURL;
@dynamic type;
@dynamic url;

@synthesize thumbnail;

- (void) dealloc {

	[thumbnail release];
	[super dealloc];

}

+ (BOOL) skipsNonexistantRemoteKey {

	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

+ (NSString *) keyPathHoldingUniqueValue {

	return @"url";

}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"providerName", @"provider_name",
			@"providerURL", @"provider_url",
			@"thumbnailURL", @"thumbnail_url",
			@"text", @"description",
			@"title", @"title",
			@"url", @"url",
			@"type", @"type",
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

- (NSString *) thumbnailFilePath {

	NSString *primitivePath = [self primitiveValueForKey:@"thumbnailFilePath"];
	
	if (primitivePath)
		return primitivePath;
	
	if (!self.thumbnailURL)
		return nil;
	
	NSURL *thumbnailURL = [NSURL URLWithString:self.thumbnailURL];
	if (!thumbnailURL)
		thumbnailURL = [NSURL URLWithString:[self.thumbnailURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	if (thumbnailURL && ![thumbnailURL isFileURL]) {

		NSURL *ownURL = [[self objectID] URIRepresentation];
		
		[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:thumbnailURL withCompletionBlock:^(NSURL *tempFileURLOrNil) {
			
			if (!tempFileURLOrNil)
				return;
					
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAOpenGraphElement *foundGraphElement = (WAOpenGraphElement *)[context irManagedObjectForURI:ownURL];
			foundGraphElement.thumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForFileAtURL:tempFileURLOrNil] path];
			
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

	if (thumbnail)
		return thumbnail;
	
	if (!self.thumbnailFilePath)
		return nil;
	
	[self willChangeValueForKey:@"thumbnail"];
	thumbnail = [[UIImage imageWithContentsOfFile:self.thumbnailFilePath] retain];
	[self didChangeValueForKey:@"thumbnail"];
	
	return thumbnail;

}





+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	if ([aLocalKeyPath isEqualToString:@"thumbnailURL"])
		return [aValue isEqualToString:@""] ? nil : aValue;
	
	return aValue;

}


- (BOOL) validateForUpdate:(NSError **)error {

	if (self.thumbnailURL)
	if (![[NSURL URLWithString:self.thumbnailURL] host]) {
		
		if (error)
			*error = [NSError errorWithDomain:@"com.waveface.wammer" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
				@"Objects having a thumbnail URL should also have a host in the URL.", NSLocalizedDescriptionKey,
				self.thumbnailURL, @"offendingThumbnailURL",
			nil]];
		
		return NO;
		
	}
	
	return YES;

}

@end
