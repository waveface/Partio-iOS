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


NSString * const kWAArticleEntitySyncingErrorDomain = @"com.waveface.wammer.WAArticle.entitySyncing.error";
NSError * WAArticleEntitySyncingError (NSUInteger code, NSString *descriptionKey, NSString *reasonKey) {
	return [NSError irErrorWithDomain:kWAArticleEntitySyncingErrorDomain code:0 descriptionLocalizationKey:descriptionKey reasonLocalizationKey:reasonKey userInfo:nil];
}

NSString * const kWAArticleSyncStrategy = @"WAArticleSyncStrategy";
NSString * const kWAArticleSyncDefaultStrategy = @"WAArticleSyncMergeLastBatchStrategy";
NSString * const kWAArticleSyncFullyFetchOnlyStrategy = @"WAArticleSyncFullyFetchOnlyStrategy";
NSString * const kWAArticleSyncMergeLastBatchStrategy = @"WAArticleSyncMergeLastBatchStrategy";

NSString * const kWAArticleSyncRangeStart = @"WAArticleSyncRangeStart";
NSString * const kWAArticleSyncRangeEnd = @"WAArticleSyncRangeEnd";

NSString * const kWAArticleSyncSessionInfo = @"WAArticleSyncSessionInfo";

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
		
			@"identifier", @"post_id",
			@"owner", @"owner",	//	wraps @"creator_id"
			@"creationDeviceName", @"code_name",
			@"group", @"group",	//	wraps @"group_id"
			@"creationDate", @"timestamp",
			@"modificationDate", @"update_time",
			@"text", @"content",
			@"comments", @"comments",
			@"files", @"attachments",
			@"previews", @"previews",
			
			@"summary", @"soul",
			
		nil];
		
	});

	return mapping;

}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	if ([aLocalKeyPath isEqualToString:@"creationDate"])
		return [[WADataStore defaultStore] dateFromISO8601String:aValue];
	
	if ([aLocalKeyPath isEqualToString:@"modificationDate"])
		return [[WADataStore defaultStore] dateFromISO8601String:aValue];
	
	if ([aLocalKeyPath isEqualToString:@"identifier"])
		return IRWebAPIKitStringValue(aValue);
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"WAGroup", @"group",
		@"WAComment", @"comments",
		@"WAUser", @"owner",
		@"WAPreview", @"previews",
		@"WAFile", @"attachments",
	
	nil];

}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSMutableDictionary *returnedDictionary = [incomingRepresentation mutableCopy];

	NSString *creatorID = [incomingRepresentation objectForKey:@"creator_id"];
	NSString *articleID = [incomingRepresentation objectForKey:@"post_id"];
	NSString *groupID = [incomingRepresentation objectForKey:@"group_id"];

	if (creatorID)
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:creatorID forKey:@"user_id"] forKey:@"owner"];

	if (groupID)
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:groupID forKey:@"group_id"] forKey:@"group"];
	
	NSArray *comments = [incomingRepresentation objectForKey:@"comments"];
	if ([comments count] && articleID) {
	
		NSMutableArray *transformedComments = [comments mutableCopy];
		
		[comments enumerateObjectsUsingBlock: ^ (NSDictionary *aCommentRep, NSUInteger idx, BOOL *stop) {
		
			NSMutableDictionary *transformedComment = [aCommentRep mutableCopy];
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

  [self synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
  
    kWAArticleSyncMergeLastBatchStrategy, kWAArticleSyncStrategy,
  
  nil] completion:completionBlock];

}

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(void (^)(BOOL, NSManagedObjectContext *, NSArray *, NSError *))completionBlock {

  WAArticleSyncStrategy syncStrategy =	[options objectForKey:kWAArticleSyncStrategy];
  
  WARemoteInterface *ri = [WARemoteInterface sharedInterface];
  WADataStore *ds = [WADataStore defaultStore];
  NSString *usedGroupIdentifier = ri.primaryGroupIdentifier;
  NSUInteger usedBatchLimit = ri.defaultBatchSize;
	
	if (!usedGroupIdentifier) {
		completionBlock(NO, nil, nil, [NSError errorWithDomain:@"com.waveface.wammer.dataStore.article" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
			@"Article sync requires a primary group identifier", NSLocalizedDescriptionKey,
		nil]]);
		return;
	}
  
  if ([syncStrategy isEqual:kWAArticleSyncMergeLastBatchStrategy]) {
  
    //  Merging the last batch only, don’t care about the vaccum at all — this is less expensive but has the potential to leave lots of vacuum in the application
    
    [ri retrieveLatestPostsInGroup:usedGroupIdentifier withBatchLimit:usedBatchLimit onSuccess:^(NSArray *postReps) {
    
      NSManagedObjectContext *context = [ds disposableMOC];
      context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

      NSArray *touchedObjects = [[self class] insertOrUpdateObjectsUsingContext:context withRemoteResponse:postReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];

			NSError *savingError = nil;
			if ([context save:&savingError])
				NSLog(@"Error saving: %@", savingError);
							
      if (completionBlock)
        completionBlock(YES, context, touchedObjects, nil);
      
    } onFailure:^(NSError *error) {
    
      if (completionBlock)
        completionBlock(NO, nil, nil, error);
    
    }];
    
  } else if ([syncStrategy isEqual:kWAArticleSyncFullyFetchOnlyStrategy]) {
	
    NSMutableDictionary *sessionInfo = [options objectForKey:kWAArticleSyncSessionInfo];
    
    if (!sessionInfo)
      sessionInfo = [NSMutableDictionary dictionary];
      
    NSMutableDictionary *optionsContinuation = [options mutableCopy];
    [optionsContinuation setObject:sessionInfo forKey:kWAArticleSyncSessionInfo];
    
    dispatch_queue_t sessionQueue = ((^ {
      
      dispatch_queue_t returnedQueue = [[sessionInfo objectForKey:@"sessionQueue"] pointerValue];
      if (!returnedQueue) {
        returnedQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@.%@.temporaryQueue",NSStringFromClass([self class]), NSStringFromSelector(_cmd)] UTF8String], DISPATCH_QUEUE_SERIAL);
        [sessionInfo setObject:[NSValue valueWithPointer:returnedQueue] forKey:@"sessionQueue"];
      }
      
      return returnedQueue;
      
    })());
    
    dispatch_async(sessionQueue, ^{
		
			NSString * const kObjectURIs = @"objectURIs";
    
			NSMutableArray *objectURIs = [sessionInfo objectForKey:kObjectURIs];
      
      if (!objectURIs) {
        objectURIs = [NSMutableArray array];
				[sessionInfo setObject:objectURIs forKey:kObjectURIs];
      }
			
      [ds fetchLatestArticleInGroup:usedGroupIdentifier onSuccess:^(NSString *identifier, WAArticle *article) {
			
        NSString *referencedPostIdentifier = identifier;
        NSDate *referencedPostDate = identifier ? nil : [NSDate distantPast];
        
        if (article.creationDate) {
          referencedPostDate = article.creationDate;
          referencedPostIdentifier = nil;
        }
				
        [ri retrievePostsInGroup:usedGroupIdentifier relativeToPost:referencedPostIdentifier date:referencedPostDate withSearchLimits:usedBatchLimit filter:nil onSuccess:^(NSArray *postReps) {
				
          dispatch_async(sessionQueue, ^ {
					
						__block BOOL shouldContinue = NO;
						
						[postReps enumerateObjectsUsingBlock: ^ (NSDictionary *aPost, NSUInteger idx, BOOL *stop) {
							
							if (![[aPost valueForKeyPath:@"post_id"] isEqual:identifier]) {
								shouldContinue = YES;
								*stop = YES;
							}
							
						}];
						
            if (shouldContinue) {
						
							NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
							context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
						
							NSArray *touchedObjects = [[self class] insertOrUpdateObjectsUsingContext:context withRemoteResponse:postReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
							
							NSError *savingError = nil;
							if ([context save:&savingError]) {
							
								[objectURIs addObjectsFromArray:[touchedObjects irMap: ^ (NSManagedObject *obj, NSUInteger index, BOOL *stop) {
									
									return [[obj objectID] URIRepresentation];
									
								}]];
								
								dispatch_async(dispatch_get_main_queue(), ^{
									
									[self synchronizeWithOptions:optionsContinuation completion:completionBlock];
									
								});

							} else {
							
								if (completionBlock)
									completionBlock(NO, context, objectURIs, savingError);
							
							}
							              
            } else {
						
							NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
							NSArray *savedObjects = [objectURIs irMap: ^ (NSURL *anObjectURI, NSUInteger index, BOOL *stop) {
								
								return [context irManagedObjectForURI:anObjectURI];
								
							}];
							
              if (completionBlock)
                completionBlock(YES, context, savedObjects, nil);
              
              dispatch_release(sessionQueue);
							
						}
            
          });
        
        } onFailure:^(NSError *error) {
				
          if (completionBlock)
            completionBlock(NO, nil, nil, error);
            
          dispatch_release(sessionQueue);
          
        }];

      }];
      
    });
      
  } else {
  
    NSParameterAssert(NO);
  
  }
  
}

- (void) synchronizeWithCompletion:(WAEntitySyncCallback)completionBlock {

  [self synchronizeWithOptions:nil completion:completionBlock];

}

- (void) synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {

	/*
	
		The general idea:
		
		
		First, see if the article is only a draft.
		
		- If it’s not a draft, load the entire remote representation into memory, but do not put them in the Data Store yet.
		
		
		If there’s a remote representation, and it matches local representation, bail.
		
		-	We assume that if the modification date on the remote representation matches local timestamp, both entities are equal and holds the same data.
		-	It’s no longer necessary to do any work because we totally assume that if the timestamps match things will be fine.
		-	HOWEVER, debug builds will do more work and assert equivalency.
		
		
		If things differ, we need to do some more work:
		
		-	For every single attachment which lacks a remote identifier, we need to upload it and create an identifier for it
		-	For every preview (we currently only have one) we need to generate a representation
		
		
		Finally, invoke either the update API or the post creation API.
	
	*/

	id mergePolicy = [options objectForKey:kWAMergePolicy];
	if (!mergePolicy)
		mergePolicy = kWAOverwriteWithLatestMergePolicy;
	
	NSAssert1(mergePolicy == kWAOverwriteWithLatestMergePolicy, @"Merge policies (got %@) other than kWAOverwriteWithLatestMergePolicy are not implemented", mergePolicy);
	
	
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	NSMutableArray *operations = [NSMutableArray array];
	NSMutableDictionary *context = [NSMutableDictionary dictionary];
	
	NSString * const kPostExistingRemoteRep = @"postExistingRemoteRep";
	NSString * const kPostExistingRemoteRepDate = @"postExistingRemoteRepDate";
	NSString * const kPostWebPreview = @"postWebPreview";
	NSString * const kPostAttachmentIDs = @"postAttachmentIDs";
	NSString * const kPostCoverPhoto = @"postCoverPhotoID";
	NSString * const kPostLocalModDate = @"postLocalModDate";
	
	NSURL * const postEntityURL = [[self objectID] URIRepresentation];
	NSString * const postID = self.identifier;
	NSString * const postText = self.text;
	NSString * const groupID = self.group.identifier ? self.group.identifier : ri.primaryGroupIdentifier;
	NSDate * const postCreationDate = self.creationDate;
	NSDate * const postModificationDate = self.modificationDate;
	
	BOOL isDraft = ([self.draft isEqualToNumber:(id)kCFBooleanTrue] || !self.identifier);
	BOOL isFavorite = [self.favorite isEqualToNumber:(id)kCFBooleanTrue];
	
	if (!isDraft) {
	
		NSLog(@"Article not draft: Fetching remote state for potential merging");
		
		[operations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock:^(IRAsyncOperationCallback callback) {
		
			[ri retrievePost:postID inGroup:groupID onSuccess:^(NSDictionary *postRep) {

				callback(postRep);
				
			} onFailure:^(NSError *error) {
			
				callback(error);
				
			}];
			
		} completionBlock:^(id results) {
		
			if ([results isKindOfClass:[NSDictionary class]]) {

				[context setObject:results forKey:kPostExistingRemoteRep];
				
			}
			
		}]];
	
	}
	
	
	[operations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock:^(IRAsyncOperationCallback callback) {
	
		NSDictionary *postExistingRemoteRep = [context objectForKey:kPostExistingRemoteRep];
		if (!postExistingRemoteRep) {
			callback((id)kCFBooleanTrue);
			return;
		}
		
		//	Compare timestamp, return boxed nscomparisonresult
		
		NSDictionary *mapping = [WAArticle remoteDictionaryConfigurationMapping];
		
		id (^mappedValue)(NSString *) = ^ (NSString *localKeyPath) {
		
			NSString *remoteKeyPath = [[mapping allKeysForObject:localKeyPath] lastObject];	//	Assumed that there will only be one key pointing to this object
			id remoteValue = [postExistingRemoteRep objectForKey:remoteKeyPath];
			
			return [WAArticle transformedValue:remoteValue fromRemoteKeyPath:remoteKeyPath toLocalKeyPath:localKeyPath];
		
		};
		
		NSDate *remoteCreationDate = mappedValue(@"creationDate");
		NSDate *remoteModificationDate = mappedValue(@"modificationDate");
		NSDate *remoteDate = remoteModificationDate ? remoteModificationDate : remoteCreationDate;
		NSDate *localDate = postModificationDate ? postModificationDate : postCreationDate;
		
		if (!remoteDate || !localDate) {
			callback(WAArticleEntitySyncingError(0, @"Can not determine if the local copy is latest, skipping sync to prevent accidental overwriting.", nil));
			return;
		}
		
		[context setObject:remoteDate forKey:kPostExistingRemoteRepDate];
		[context setObject:localDate forKey:kPostLocalModDate];
		
		NSComparisonResult comparisonResult = [remoteDate compare:localDate];
		switch (comparisonResult) {
		
			case NSOrderedAscending: {
				NSLog(@"Remote date %@ newer than local date %@", remoteDate, localDate);
				break;
			}
			
			case NSOrderedSame: {
				NSLog(@"Remote date %@ equivalent to local date %@", remoteDate, localDate);
				callback(nil);
				return;
			}
			
			case NSOrderedDescending: {
				NSLog(@"Remote date %@ older than local date %@", remoteDate, localDate);
				break;
			}
		
		}

		callback([NSValue valueWithBytes:&(NSComparisonResult){ comparisonResult } objCType:@encode(__typeof__(NSComparisonResult))]);
		
	} completionBlock:nil]];
	
	
	[self.fileOrder enumerateObjectsUsingBlock: ^ (NSURL *aFileURL, NSUInteger idx, BOOL *stop) {
	
		NSLog(@"Emiting operation for WAFile at %@", aFileURL);
		
		[operations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock: ^ (void(^aCallback)(id results)) {
		
			//	Re-fetch for clarity, use the shared MOC to avoid duplicating state, as long as we are careful NOT to mutate anything.
		
			NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
			WAFile *representedFile = (WAFile *)[context irManagedObjectForURI:aFileURL];
			if (!representedFile) {
				aCallback(WAArticleEntitySyncingError(0, [NSString stringWithFormat:@"Unable to find WAFile entity at %@", aFileURL], nil));
				return;
			}
			
			if (representedFile.identifier) {
				aCallback(representedFile.identifier);
				return;
			}
			
			[representedFile synchronizeWithCompletion:^(BOOL didFinish, NSManagedObjectContext *context, NSArray *objects, NSError *error) {
			
				if (!didFinish) {
					aCallback(error);
					return;
				}
			
				NSCParameterAssert([objects count] == 1);
				
				WAFile *savedFile = (WAFile *)[objects lastObject];
				NSCParameterAssert(savedFile.article);
				NSCParameterAssert(savedFile.identifier);
				aCallback(savedFile.identifier);
				
				NSLog(@"synchronized file %@ with identifier %@", savedFile, savedFile.identifier);
				
			}];
			
		} completionBlock:^(id result) {
		
			if (![result isKindOfClass:[NSString class]])
				return;
			
			NSMutableArray *attachmentIDs = [context objectForKey:kPostAttachmentIDs];
			if (!attachmentIDs) {
				attachmentIDs = [NSMutableArray array];
				[context setObject:attachmentIDs forKey:kPostAttachmentIDs];
			}
			
			NSParameterAssert([attachmentIDs isKindOfClass:[NSMutableArray class]]);
			[attachmentIDs addObject:result];
		
		}]];
		
	}];
	
	
	WAPreview * const anyPreview = [self.previews anyObject];
	NSString * const previewURLString = (anyPreview.graphElement.url ? anyPreview.graphElement.url : anyPreview.url);
	NSURL * const previewURL = previewURLString ? [NSURL URLWithString:previewURLString] : nil;
	
	if (previewURL) {
	
		NSLog(@"Emitting operation for preview at %@", previewURL);
		NSString * const previewImageURL = anyPreview.graphElement.primaryImage.imageRemoteURL;
	
		[operations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock:^(IRAsyncOperationCallback callback) {
		
			[ri retrievePreviewForURL:previewURL onSuccess:^(NSDictionary *aPreviewRep) {

				callback(aPreviewRep);
				
			} onFailure:^(NSError *error) {
			
				callback(error);
				
			}];
		
		} completionBlock:^(id results) {
		
			if (![results isKindOfClass:[NSDictionary class]])
				return;
			
			if (previewImageURL) {
			
				NSMutableDictionary *previewEntity = [(NSDictionary *)results mutableCopy];
				[previewEntity setObject:previewImageURL forKey:@"thumbnail_url"];
				
				[context setObject:previewEntity forKey:kPostWebPreview];
			
			} else {
			
				[context setObject:results forKey:kPostWebPreview];
			
			}
			
		}]];
	
	}
	
	
	[operations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock:^(IRAsyncOperationCallback callback) {
	
		NSLog(@"handling article update or creation with context %@", context);
		
		NSArray *attachments = [context objectForKey:kPostAttachmentIDs];
		NSString *mainAttachmentID = [context objectForKey:kPostCoverPhoto];
		NSDictionary *preview = [context objectForKey:kPostWebPreview];
		
		if (isDraft) {
		
			[ri createPostInGroup:groupID withContentText:postText attachments:attachments preview:preview onSuccess:^(NSDictionary *postRep) {
				
				callback(postRep);
				
			} onFailure: ^ (NSError *error) {
			
				callback(error);
				
			}];
					
		} else {
		
			NSDate *lastPostModDate = [context objectForKey:kPostExistingRemoteRepDate];
		
			[ri updatePost:postID inGroup:groupID withText:postText attachments:attachments	mainAttachment:mainAttachmentID	preview:preview favorite:isFavorite replacingDataWithDate:lastPostModDate	onSuccess:^(NSDictionary *postRep) {
			
				callback(postRep);
				
			} onFailure:^(NSError *error) {

				callback(error);
				
			}];
		
		}
		
	} completionBlock:^(id results) {
	
		if ([results isKindOfClass:[NSDictionary class]]) {
		
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAArticle *savedPost = (WAArticle *)[context irManagedObjectForURI:postEntityURL];
			savedPost.draft = (id)kCFBooleanFalse;
			
			NSParameterAssert([[results valueForKeyPath:@"attachments"] count] == [savedPost.files count]);
			
			NSArray *touchedObjects = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObject:results] usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
			NSParameterAssert([touchedObjects count]);
			
			NSError *savingError = nil;
			BOOL didSave = [context save:&savingError];
			
			completionBlock(didSave, context, [NSArray arrayWithObject:savedPost], didSave ? nil : savingError);
		
		} else {
		
			NSError *error = (NSError *)([results isKindOfClass:[NSError class]] ? results : nil);
			completionBlock(NO, nil, nil, error);
			
		}
		
	}]];
	
	
	[operations enumerateObjectsUsingBlock: ^ (IRAsyncBarrierOperation *operation, NSUInteger idx, BOOL *stop) {
	
		if (idx > 0)
			[operation addDependency:[operations objectAtIndex:(idx - 1)]];
		
	}];
	
	__block NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
	[operationQueue setSuspended:YES];
	[operationQueue setMaxConcurrentOperationCount:1];
	
	NSOperation *cleanupOp = [NSBlockOperation blockOperationWithBlock:^{
	
		operationQueue = nil;
		
	}];
	
	for (NSOperation *op in operations)
		[cleanupOp addDependency:op];

	[operationQueue addOperations:operations waitUntilFinished:NO];
	[operationQueue addOperation:cleanupOp];
	[operationQueue setSuspended:NO];
	
	return;
	
	//	Legacy stuff to be deleted here
	
	if (isDraft) {
	
		NSURL *ownURL = [[self objectID] URIRepresentation];
	
		__block NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
		__block NSMutableDictionary *resultsDictionary = [NSMutableDictionary dictionary];
		
		if (self.text)
			[resultsDictionary setObject:self.text forKey:@"postText"];
		
		if (self.group.identifier)
			[resultsDictionary setObject:self.group.identifier forKey:@"postGroupIdentifier"];
		else
			[resultsDictionary setObject:ri.primaryGroupIdentifier forKey:@"postGroupIdentifier"];
		
		[operationQueue setSuspended:YES];
		
		operationQueue.maxConcurrentOperationCount = 1;
		
		BOOL (^dependentOperationCancelledOrFailed)(IRAsyncOperation *) = ^ (IRAsyncOperation *self) {
			
			for (IRAsyncOperation *op in self.dependencies)
			if ([op isCancelled] || ([op isFinished] && (!op.results || [op.results isKindOfClass:[NSError class]])))
				return YES;
			
			return NO;
			
		};
		
		NSError *dependentOperationCancelledOrFailedError = WAArticleEntitySyncingError(0, @"ARTICLE_SYNC_ERROR_DEPENDENT_OPERATION_FAILED_TITLE", @"ARTICLE_SYNC_ERROR_DEPENDENT_OPERATION_FAILED_DESCRIPTION");
	
		WAPreview *aPreview = [self.previews anyObject];
		NSURL *previewURL = [NSURL URLWithString:(aPreview.graphElement.url ? aPreview.graphElement.url : aPreview.url)];
		
		if (previewURL) {
		
			NSString *primaryImageURL = aPreview.graphElement.primaryImage.imageRemoteURL;
			if (primaryImageURL)
				[resultsDictionary setObject:primaryImageURL forKey:@"previewImageURL"];
			
			__block IRAsyncOperation *nrPreviewOp = [IRAsyncOperation operationWithWorkerBlock: ^ (void(^aCallback)(id results)) {
			
				[ri retrievePreviewForURL:previewURL onSuccess:^(NSDictionary *aPreviewRep) {
				
					aCallback(aPreviewRep);
					
				} onFailure: ^ (NSError *error) {
				
					aCallback(error);
					
				}];
				
			} completionBlock: ^ (id results) {
			
				if ([results isKindOfClass:[NSError class]])
					return;
				
				[resultsDictionary setObject:results forKey:@"previewEntity"];
				
			}];
			
			[operationQueue addOperation:nrPreviewOp];
		
		}
		
		
		
		__block IRAsyncOperation *nrFinalOperation = [IRAsyncOperation operationWithWorkerBlock: ^ (void(^aCallback)(id results)) {
		
			if (dependentOperationCancelledOrFailed(nrFinalOperation)) {
			
				for (IRAsyncOperation *dependentOp in nrFinalOperation.dependencies) {
					if ([dependentOp.results isKindOfClass:[NSError class]]) {					
						aCallback((NSError *)dependentOp.results);
						return;
					}
				}
			
				aCallback(dependentOperationCancelledOrFailedError);
				return;
				
			}
		
			NSString *postGroupIdentifier = [resultsDictionary objectForKey:@"postGroupIdentifier"];
			NSString *postText = [resultsDictionary objectForKey:@"postText"];
			NSArray *attachmentIdentifiers = [resultsDictionary objectForKey:@"fileIdentifiers"];
			NSMutableDictionary *previewEntity = [[resultsDictionary objectForKey:@"previewEntity"] mutableCopy];
			NSString *previewImageURL = [resultsDictionary objectForKey:@"previewImageURL"];
			
			if (previewEntity && previewImageURL)
				[previewEntity setObject:previewImageURL forKey:@"thumbnail_url"];
			
			[ri createPostInGroup:postGroupIdentifier withContentText:postText attachments:attachmentIdentifiers preview:previewEntity onSuccess:^(NSDictionary *postRep) {
				
				aCallback(postRep);
				
			} onFailure: ^ (NSError *error) {
			
				aCallback(error);
				
			}];
			
		} completionBlock: ^ (id results) {
		
			if ([results isKindOfClass:[NSDictionary class]]) {
			
				
			
			} else {
			
				completionBlock(NO, nil, nil, results);
			
			}
		
		}];
		
		NSArray *allOps = operationQueue.operations;
		[allOps enumerateObjectsUsingBlock: ^ (NSOperation *anOperation, NSUInteger idx, BOOL *stop) {
		
			if (idx != 0)
				[anOperation addDependency:[allOps objectAtIndex:(idx - 1)]];

			[nrFinalOperation addDependency:anOperation];
			
		}];
		
		[operationQueue addOperation:nrFinalOperation];
		[operationQueue setSuspended:NO];
	
	} else {
	
		[ri retrievePost:self.identifier inGroup:self.group.identifier onSuccess:^(NSDictionary *postRep) {
		
			//	TBD: Look at postRep, find the latest one, overwrite either part
			
			if (!completionBlock)
				return;
			
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			
			NSArray *touchedObjects = [[self class] insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObject:postRep] usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
			
			WAArticle *savedPost = (WAArticle *)[touchedObjects lastObject];
			savedPost.draft = (id)kCFBooleanFalse;
			
			NSError *savingError = nil;
			BOOL didSave = [context save:&savingError];
			
			completionBlock(didSave, context, [NSArray arrayWithObject:savedPost], didSave ? nil : savingError);	
			
		} onFailure:^(NSError *error) {
		
			if (!completionBlock)
				return;
				
			completionBlock(NO, nil, nil, error);
			
		}];
	
	}

}

@end
