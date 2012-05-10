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
NSString * const kWAArticleSyncDefaultStrategy = @"WAArticleSyncDefaultStrategy";
NSString * const kWAArticleSyncFullyFetchStrategy = @"WAArticleSyncFullyFetchOnlyStrategy";
NSString * const kWAArticleSyncMergeLastBatchStrategy = @"WAArticleSyncMergeLastBatchStrategy";
NSString * const kWAArticleSyncDeltaFetchStrategy = @"WAArticleSyncDeltaFetchStrategy";

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
			@"group", @"group",	//	wraps @"group_id"
			@"owner", @"owner",	//	wraps @"creator_id"
			@"files", @"attachments",
			@"previews", @"previews",
			@"representingFile", @"representingFile",	//	wraps @"cover_attach"
			
			@"creationDeviceName", @"code_name",
			@"creationDate", @"timestamp",
			@"modificationDate", @"update_time",
			@"text", @"content",
			@"comments", @"comments",
			@"summary", @"soul",
			@"favorite", @"favorite",
			@"hidden", @"hidden",			
			
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
	
	if ([aLocalKeyPath isEqualToString:@"favorite"])
		return (![aValue isEqual:@"false"] && ![aValue isEqual:@"0"] && ![aValue isEqual:[NSNumber numberWithInt:0]]) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;
	
	if ([aLocalKeyPath isEqualToString:@"hidden"])
		return (![aValue isEqual:@"false"] && ![aValue isEqual:@"0"] && ![aValue isEqual:[NSNumber numberWithInt:0]]) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"WAGroup", @"group",
		@"WAComment", @"comments",
		@"WAUser", @"owner",
		@"WAPreview", @"previews",
		@"WAFile", @"attachments",
		@"WAFile", @"representingFile",
	
	nil];

}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSMutableDictionary *returnedDictionary = [incomingRepresentation mutableCopy];

	NSString *creatorID = [incomingRepresentation objectForKey:@"creator_id"];
	NSString *articleID = [incomingRepresentation objectForKey:@"post_id"];
	NSString *groupID = [incomingRepresentation objectForKey:@"group_id"];
	NSString *representingFileID = [incomingRepresentation objectForKey:@"cover_attach"];

	if ([creatorID length])
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:creatorID forKey:@"user_id"] forKey:@"owner"];

	if ([groupID length])
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:groupID forKey:@"group_id"] forKey:@"group"];
	
	if ([representingFileID length])
		[returnedDictionary setObject:[NSDictionary dictionaryWithObject:representingFileID forKey:@"object_id"] forKey:@"representingFile"];
	
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
  
    kWAArticleSyncDefaultStrategy, kWAArticleSyncStrategy,
  
  nil] completion:completionBlock];

}

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(void (^)(BOOL, NSManagedObjectContext *, NSArray *, NSError *))completionBlock {

  WAArticleSyncStrategy wantedStrategy = [options objectForKey:kWAArticleSyncStrategy];
	WAArticleSyncStrategy syncStrategy = wantedStrategy;
	
	if ([wantedStrategy isEqual:kWAArticleSyncDefaultStrategy]) {
		
		if ([[WADataStore defaultStore] lastContentSyncDate]) {
			syncStrategy = kWAArticleSyncDeltaFetchStrategy;
		}
		
	} else {
	
		syncStrategy = kWAArticleSyncFullyFetchStrategy;
		
	}
  
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
	
	if ([syncStrategy isEqual:kWAArticleSyncDefaultStrategy]) {
		
		if ([[WADataStore defaultStore] lastContentSyncDate]) {
			
			syncStrategy = kWAArticleSyncDeltaFetchStrategy;
			
		} else {

			syncStrategy = kWAArticleSyncFullyFetchStrategy;
		
		}
		
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
							
			[[WADataStore defaultStore] setLastContentSyncDate:[NSDate date]];

      if (completionBlock)
        completionBlock(YES, context, touchedObjects, nil);
      
    } onFailure:^(NSError *error) {
    
      if (completionBlock)
        completionBlock(NO, nil, nil, error);
    
    }];
    
  } else if ([syncStrategy isEqual:kWAArticleSyncFullyFetchStrategy]) {
	
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
			
      [ds fetchLatestCreatedArticleInGroup:usedGroupIdentifier onSuccess:^(NSString *identifier, WAArticle *article) {
			
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
						
						dispatch_async(dispatch_get_main_queue(), ^{
						
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
								
								[[WADataStore defaultStore] setLastContentSyncDate:[NSDate date]];
								
								if (completionBlock)
									completionBlock(YES, context, savedObjects, nil);
								
								dispatch_release(sessionQueue);
								
							}
            
						});
					
          });
        
        } onFailure:^(NSError *error) {
				
          if (completionBlock)
            completionBlock(NO, nil, nil, error);
            
          dispatch_release(sessionQueue);
          
        }];

      }];
      
    });
      
  } else if ([syncStrategy isEqual:kWAArticleSyncDeltaFetchStrategy]){
	
		NSDate *usedDate = [[[WADataStore defaultStore] lastContentSyncDate] dateByAddingTimeInterval:1];
		NSCParameterAssert(usedDate);
		
		__block BOOL haveChangesSinceLastDate = NO;
		__block NSDate *knownLatestDate = usedDate;
		
		[ri retrieveChangedArticlesSince:usedDate inGroup:usedGroupIdentifier onProgress:^(NSArray *changedArticleReps) {
		
			dispatch_sync(dispatch_get_main_queue(), ^{
				
				NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
				NSArray *articles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:changedArticleReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
				
				[context save:nil];
				
				haveChangesSinceLastDate = YES;
				
				for (WAArticle *article in articles) {
					
					NSDate *timestamp = article.modificationDate;
					if (!timestamp)
						timestamp = article.creationDate;
					
					if (timestamp)
						knownLatestDate = [knownLatestDate laterDate:timestamp];
					
					NSCParameterAssert(knownLatestDate);
					
				}
			
			});

		} onSuccess:^{
		
			//	Otherwise, async changes will be ignored, which is very bad
			
			if (haveChangesSinceLastDate) {
				[[WADataStore defaultStore] setLastContentSyncDate:knownLatestDate];
			}
			
			knownLatestDate = nil;
			
			if (completionBlock)
				completionBlock(YES, nil, nil, nil);
			
		} onFailure:^(NSError *error) {
		
			knownLatestDate = nil;

			if (completionBlock)
				completionBlock(NO, nil, nil, error);
			
		}];
				
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

	id mergePolicy = [options objectForKey:WAMergePolicyKey];
	if (!mergePolicy)
		mergePolicy = WAOverwriteWithLatestMergePolicy;
	
	NSAssert1(mergePolicy == WAOverwriteWithLatestMergePolicy, @"Merge policies (got %@) other than kWAOverwriteWithLatestMergePolicy are not implemented", mergePolicy);
	
	
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	NSMutableArray *operations = [NSMutableArray array];
	NSMutableDictionary *context = [NSMutableDictionary dictionary];
	
	NSString * const kPostExistingRemoteRep = @"postExistingRemoteRep";
	NSString * const kPostExistingRemoteRepDate = @"postExistingRemoteRepDate";
	NSString * const kPostWebPreview = @"postWebPreview";
	NSString * const kPostAttachmentIDs = @"postAttachmentIDs";
	NSString * const kPostLocalModDate = @"postLocalModDate";
	
	NSURL * const postEntityURL = [[self objectID] URIRepresentation];
	NSString * const postID = self.identifier;
	NSString * const postText = self.text;
	NSString * const groupID = self.group.identifier ? self.group.identifier : ri.primaryGroupIdentifier;
	NSString * const postCoverPhotoID = self.representingFile.identifier;
	NSDate * const postCreationDate = self.creationDate;
	NSDate * const postModificationDate = self.modificationDate;
	
	BOOL isDraft = ([self.draft isEqualToNumber:(id)kCFBooleanTrue] || !self.identifier);
	BOOL isFavorite = [self.favorite isEqualToNumber:(id)kCFBooleanTrue];
	BOOL isHidden = [self.hidden isEqualToNumber:(id)kCFBooleanTrue];
	
	if (!isDraft) {
	
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
		
			case NSOrderedDescending: {
				break;
			}
			
			case NSOrderedSame: {
				callback(nil);
				return;
			}
			
			case NSOrderedAscending: {
				break;
			}
		
		}

		callback([NSValue valueWithBytes:&(NSComparisonResult){ comparisonResult } objCType:@encode(__typeof__(NSComparisonResult))]);
		
	} completionBlock:nil]];
	
	
	[self.fileOrder enumerateObjectsUsingBlock: ^ (NSURL *aFileURL, NSUInteger idx, BOOL *stop) {
	
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
			
			[representedFile synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
			
				kWAFileSyncReducedQualityStrategy, kWAFileSyncStrategy,
			
			nil] completion:^(BOOL didFinish, NSManagedObjectContext *context, NSArray *objects, NSError *error) {
			
				if (!didFinish) {
					aCallback(error);
					return;
				}
			
				NSCParameterAssert([objects count] == 1);
				
				WAFile *savedFile = (WAFile *)[objects lastObject];
				NSCParameterAssert(savedFile.article);
				NSCParameterAssert(savedFile.identifier);
				aCallback(savedFile.identifier);
				
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
	
		NSArray *attachments = [context objectForKey:kPostAttachmentIDs];
		NSDictionary *preview = [context objectForKey:kPostWebPreview];
		
		if (isDraft) {
		
			[ri createPostInGroup:groupID withContentText:postText attachments:attachments preview:preview onSuccess:^(NSDictionary *postRep) {
				
				callback(postRep);
				
			} onFailure: ^ (NSError *error) {
			
				callback(error);
				
			}];
					
		} else {
		
			NSDate *lastPostModDate = [context objectForKey:kPostExistingRemoteRepDate];
		
			[ri updatePost:postID inGroup:groupID withText:postText attachments:attachments mainAttachment:postCoverPhotoID preview:preview favorite:isFavorite hidden:isHidden replacingDataWithDate:lastPostModDate onSuccess:^(NSDictionary *postRep) {
			
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
			
			if (!savedPost.identifier) {
			
				NSDictionary *mapping = [WAArticle remoteDictionaryConfigurationMapping];
				NSString *identifierHostKey = @"identifier";
				NSString *identifierNetworkKey = [[mapping allKeysForObject:identifierHostKey] lastObject];
				
				NSString *identifier = [WAArticle transformedValue:[results objectForKey:identifierNetworkKey] fromRemoteKeyPath:identifierNetworkKey toLocalKeyPath:identifierHostKey];
				
				savedPost.identifier = identifier;
			
			}			
			
			NSArray *touchedObjects = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObject:results] usingMapping:nil options:IRManagedObjectOptionIndividualOperations];

			if (savedPost)
				NSParameterAssert([[results valueForKeyPath:@"attachments"] count] == [savedPost.files count]);
			
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

}

@end
