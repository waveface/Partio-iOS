//
//  WAArticle+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticle+WARemoteInterfaceEntitySyncing.h"
#import "WAFile+WARemoteInterfaceEntitySyncing.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "Foundation+IRAdditions.h"
#import "IRAsyncOperation.h"

@implementation WAArticle (WARemoteInterfaceEntitySyncing)

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
		
		/*
		
		    post_id: <post_id>,     // unique   
    creator_id: <uid>,
    code_name: (String) nameOfCreatingDevice,
    group_id: <group_id>,
    timestamp: (Date) aTimestamp,
    content: (String) contentText,
    comment_count: (Number) numberOfComments,
    comments: (Array) zeroOrMoreCommentEntities,
    attachment_id_array: (Array) arrayOfAttachmentId,
    attachments_count: (Number) numberOfFiles,
    attachments: (Array) zeroOrMoreFileEntities,
    preview: (Array) zeroOrMore PreviewEntities,
    soul: aSoulEntity

		
		*/
		
			@"identifier", @"post_id",
			@"owner", @"owner",	//	wraps @"creator_id"
			@"creationDeviceName", @"code_name",
			@"group", @"group",	//	wraps @"group_id"
			@"timestamp", @"timestamp",
			@"text", @"content",
			@"comments", @"comments",
			@"files", @"attachments",
			@"previews", @"previews",
			
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

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"WAFile", @"files",
		@"WAGroup", @"group",
		@"WAComment", @"comments",
		@"WAUser", @"owner",
		@"WAPreview", @"previews",
		@"WAFile", @"attachments",
	
	nil];

}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSMutableDictionary *returnedDictionary = [[incomingRepresentation mutableCopy] autorelease];

	NSString *creatorID = [incomingRepresentation objectForKey:@"creator_id"];
	NSString *articleID = [incomingRepresentation objectForKey:@"post_id"];
	NSString *groupID = [incomingRepresentation objectForKey:@"group_id"];

	if (creatorID)
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:creatorID forKey:@"user_id"] forKey:@"owner"];

	if (groupID)
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:groupID forKey:@"group_id"] forKey:@"group"];
	
	NSArray *comments = [incomingRepresentation objectForKey:@"comments"];
	if ([comments count] && articleID) {
	
		NSMutableArray *transformedComments = [[comments mutableCopy] autorelease];
		
		[comments enumerateObjectsUsingBlock: ^ (NSDictionary *aCommentRep, NSUInteger idx, BOOL *stop) {
		
			NSMutableDictionary *transformedComment = [[aCommentRep mutableCopy] autorelease];
			NSString *commentID = [transformedComment objectForKey:@"comment_id"];
			id aTimestamp = [aCommentRep objectForKey:@"timestamp"];
			if (!aTimestamp)
				aTimestamp = IRWebAPIKitNonce();
			
			if (!commentID) {
				commentID = [NSString stringWithFormat:@"Synthesized_Article_%@_Timestamp_%@", articleID, aTimestamp];
				[transformedComment setObject:commentID forKey:@"comment_id"];
			}
			
			[transformedComments replaceObjectAtIndex:idx withObject:transformedComment];
			
		}];
		
		[returnedDictionary setObject:transformedComments forKey:@"comments"];
	
	}
	
	NSDictionary *preview = [incomingRepresentation objectForKey:@"preview"];
	
	if ([preview count]) {
	
		[returnedDictionary setObject:[NSArray arrayWithObjects:
		
			[NSDictionary dictionaryWithObjectsAndKeys:
			
				preview, @"og",
				[preview valueForKeyPath:@"url"], @"id",
			
			nil],
		
		nil] forKey:@"previews"];
	
	}
	
	return returnedDictionary;

}

+ (void) synchronizeWithCompletion:(void (^)(BOOL, NSManagedObjectContext *, NSArray *, NSError *))completionBlock {

	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	
	[ri retrieveLatestPostsInGroup:ri.primaryGroupIdentifier withBatchLimit:25 onSuccess:^(NSArray *postReps) {
	
		if (!completionBlock)
			return;
		
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
		
		NSArray *touchedObjects = [[self class] insertOrUpdateObjectsUsingContext:context withRemoteResponse:postReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
		
		completionBlock(YES, context, touchedObjects, nil);
	
	} onFailure:^(NSError *error) {
		
		if (completionBlock)
			completionBlock(NO, nil, nil, error);
		
	}];

}

- (void) synchronizeWithCompletion:(void (^)(BOOL, NSManagedObjectContext *, NSManagedObject *, NSError *))completionBlock {

	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	
	if ([self.draft isEqualToNumber:(id)kCFBooleanTrue] || !self.identifier) {
	
		NSURL *ownURL = [[self objectID] URIRepresentation];
	
		__block NSManagedObjectContext *context = [self.managedObjectContext retain];
		__block NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
		__block NSMutableDictionary *resultsDictionary = [[NSMutableDictionary dictionary] retain];
		
		if (self.text)
			[resultsDictionary setObject:self.text forKey:@"postText"];
		
		if (self.group.identifier)
			[resultsDictionary setObject:self.group.identifier forKey:@"postGroupIdentifier"];
		else
			[resultsDictionary setObject:ri.primaryGroupIdentifier forKey:@"postGroupIdentifier"];
		
		void (^cleanup)() = ^ {
			[operationQueue release];
			[resultsDictionary release];
			[context autorelease];
		};
		
		[operationQueue setSuspended:YES];
		
		operationQueue.maxConcurrentOperationCount = 1;
	
		WAPreview *aPreview = [self.previews anyObject];
		NSURL *previewURL = [NSURL URLWithString:(aPreview.url ? aPreview.url : aPreview.graphElement.url)];
		
		
		
		if (previewURL) {
		
			//	If preview, fetch it and carry on
			
			[operationQueue addOperation:[IRAsyncOperation operationWithWorkerBlock: ^ (void(^aCallback)(id results)) {
			
				[ri retrievePreviewForURL:previewURL onSuccess:^(NSDictionary *aPreviewRep) {
				
					aCallback(aPreviewRep);
					
				} onFailure: ^ (NSError *error) {
				
					aCallback(nil);
					
				}];
				
			} completionBlock: ^ (id results) {
			
				[resultsDictionary setObject:results forKey:@"previewEntity"];
				
			}]];
		
		}
		
		[self.fileOrder enumerateObjectsUsingBlock: ^ (NSURL *aFileURL, NSUInteger idx, BOOL *stop) {
		
			WAFile *representedFile = (WAFile *)[self.managedObjectContext irManagedObjectForURI:aFileURL];
			if (!representedFile)
				return;
			
			[representedFile resourceURL];
			
			NSLog(@"ADDING file %@", representedFile);
			
			[operationQueue addOperation:[IRAsyncOperation operationWithWorkerBlock: ^ (void(^aCallback)(id results)) {
				
				[representedFile synchronizeWithCompletion:^(BOOL didFinish, NSManagedObjectContext *temporalContext, NSManagedObject *prospectiveUnsavedObject, NSError *anError) {
				
					if (![temporalContext save:nil]) {
						aCallback(nil);
						return;
					}
					
					WAFile *savedFile = (WAFile *)prospectiveUnsavedObject;
					aCallback(savedFile.identifier);
					
				}];
				
			} completionBlock:^(id results) {
			
				if (!results) {
					NSLog(@"Error injecting file.");
					return;
				}
			
				NSMutableArray *fileIdentifiers = [resultsDictionary objectForKey:@"fileIdentifiers"];
				if (!fileIdentifiers) {
					fileIdentifiers = [NSMutableArray array];
					[resultsDictionary setObject:fileIdentifiers forKey:@"fileIdentifiers"];
				}
				
				[fileIdentifiers addObject:results];
			
			}]];
			
		}];
		
		IRAsyncOperation *finalOperation = [IRAsyncOperation operationWithWorkerBlock: ^ (void(^aCallback)(id results)) {
		
			NSString *postGroupIdentifier = [resultsDictionary objectForKey:@"postGroupIdentifier"];
			NSString *postText = [resultsDictionary objectForKey:@"postText"];
			NSArray *attachmentIdentifiers = [resultsDictionary objectForKey:@"fileIdentifiers"];
			NSDictionary *previewEntity = [resultsDictionary objectForKey:@"previewEntity"];

			[ri createPostInGroup:postGroupIdentifier withContentText:postText attachments:attachmentIdentifiers preview:previewEntity onSuccess:^(NSDictionary *postRep) {
				
				aCallback(postRep);
				
			} onFailure: ^ (NSError *error) {
			
				aCallback(error);
				
			}];
			
		} completionBlock: ^ (id results) {
		
			if ([results isKindOfClass:[NSDictionary class]]) {
			
				NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
				context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
				
				WAArticle *savedPost = (WAArticle *)[context irManagedObjectForURI:ownURL];
				savedPost.draft = (id)kCFBooleanFalse;
				
				[savedPost.managedObjectContext deleteObject:savedPost];
				
				NSArray *touchedPosts = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObject:results] usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
				
				completionBlock(YES, context, savedPost, nil);
			
			} else {
			
				completionBlock(NO, nil, nil, results);
			
			}
		
			dispatch_async(dispatch_get_main_queue(), ^ {
				cleanup();
			});
			
		}];
		
		[operationQueue.operations enumerateObjectsUsingBlock: ^ (NSOperation *anOperation, NSUInteger idx, BOOL *stop) {
			[finalOperation addDependency:anOperation];
		}];
		
		[operationQueue addOperation:finalOperation];
		[operationQueue setSuspended:NO];
	
	} else {
	
		[ri retrievePost:self.identifier inGroup:self.group.identifier onSuccess:^(NSDictionary *postRep) {
		
			if (!completionBlock)
				return;
			
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			
			NSArray *touchedObjects = [[self class] insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObject:postRep] usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
			
			WAArticle *savedPost = (WAArticle *)[touchedObjects lastObject];
			savedPost.draft = (id)kCFBooleanFalse;
			
			completionBlock(YES, context, savedPost, nil);	
			
		} onFailure:^(NSError *error) {
		
			if (!completionBlock)
				return;
				
			completionBlock(NO, nil, nil, error);
			
		}];
	
	}

}

@end
