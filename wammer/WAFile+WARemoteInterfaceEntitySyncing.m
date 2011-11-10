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

+ (void) synchronizeWithCompletion:(void (^)(BOOL, NSManagedObjectContext *, NSArray *, NSError *))completionBlock {

	NSParameterAssert(NO);

}

- (void) synchronizeWithCompletion:(void (^)(BOOL, NSManagedObjectContext *, NSManagedObject *, NSError *))completionBlock {

	NSParameterAssert(WAObjectEligibleForRemoteInterfaceEntitySyncing(self));

	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	NSURL *ownURL = [[self objectID] URIRepresentation];

	if (!(self.resourceURL) && (self.resourceFilePath)) {
	
		[ri createAttachmentWithFileAtURL:[NSURL fileURLWithPath:self.resourceURL] inGroup:ri.primaryGroupIdentifier representingImageURL:nil withTitle:self.text description:nil replacingAttachment:nil asType:nil onSuccess:^(NSString *attachmentIdentifier) {
		
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
