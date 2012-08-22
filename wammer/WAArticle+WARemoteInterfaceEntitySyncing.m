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
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "Foundation+IRAdditions.h"
#import "IRAsyncOperation.h"


NSString * const kWAArticleEntitySyncingErrorDomain = @"com.waveface.wammer.WAArticle.entitySyncing.error";
NSError * WAArticleEntitySyncingError (NSUInteger code, NSString *descriptionKey, NSString *reasonKey) {
	return [NSError irErrorWithDomain:kWAArticleEntitySyncingErrorDomain code:code descriptionLocalizationKey:descriptionKey reasonLocalizationKey:reasonKey userInfo:nil];
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

	NSMutableArray *fullAttachmentList = [[incomingRepresentation objectForKey:@"attachment_id_array"] mutableCopy];
	NSArray *incomingAttachmentList = [[incomingRepresentation objectForKey:@"attachments"] copy];
	NSMutableArray *returnedAttachmentList = [incomingAttachmentList mutableCopy];
	if (!returnedAttachmentList) {
		returnedAttachmentList = [[NSMutableArray alloc] init];
	}
	
	if ([fullAttachmentList count] > [incomingAttachmentList count]) {

		// dedup
		for (NSDictionary *attachment in incomingAttachmentList) {
			NSDictionary *imageMeta = [attachment objectForKey:@"image_meta"];
			if (imageMeta && [imageMeta objectForKey:@"small"] && [imageMeta objectForKey:@"medium"]) {
				[fullAttachmentList removeObject:[attachment objectForKey:@"object_id"]];
			} else {
				[returnedAttachmentList removeObject:attachment];
			}
		}
		
		for (NSString *objectID in fullAttachmentList) {
			NSString *attachString = @"/v2/attachments/view?object_id=%@&image_meta=%@";
			NSString *smallString = [NSString stringWithFormat:attachString, objectID, @"small"];
			NSString *mediumString =[NSString stringWithFormat:attachString, objectID, @"medium"];
			NSDictionary *smallDict = [NSDictionary dictionaryWithObjectsAndKeys:
																 smallString, @"url",
																 nil];
			NSDictionary *mediumDict = [NSDictionary dictionaryWithObjectsAndKeys:
																 mediumString, @"url",
																 nil];
			NSDictionary *imageMeta = [NSDictionary dictionaryWithObjectsAndKeys:
																 smallDict,  @"small",
																 mediumDict, @"medium",
																 nil];
			NSDictionary *attach = [NSDictionary dictionaryWithObjectsAndKeys:
															objectID, @"object_id",
															creatorID, @"creator_id",
															articleID, @"post_id",
															imageMeta, @"image_meta",
															@"unknown.jpeg", @"file_name",
															@"image", @"type",
															nil];
			[returnedAttachmentList addObject:attach];
		}
		[returnedDictionary setObject:returnedAttachmentList forKey:@"attachments"];
	}
	
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

+ (void) synchronizeWithCompletion:(void (^)(BOOL, NSError *))completionBlock {

  [self synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
  
    kWAArticleSyncDefaultStrategy, kWAArticleSyncStrategy,
  
  nil] completion:completionBlock];

}

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(void (^)(BOOL, NSError *))completionBlock {

	WAArticleSyncStrategy wantedStrategy = [options objectForKey:kWAArticleSyncStrategy];
	WAArticleSyncStrategy syncStrategy = wantedStrategy;
	
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	WADataStore *ds = [WADataStore defaultStore];
	NSString *usedGroupIdentifier = ri.primaryGroupIdentifier;
	NSUInteger usedBatchLimit = ri.defaultBatchSize;
	
	if (!usedGroupIdentifier) {
		completionBlock(NO, [NSError errorWithDomain:@"com.waveface.wammer.dataStore.article" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
			@"Article sync requires a primary group identifier", NSLocalizedDescriptionKey,
		nil]]);
		return;
	}
	
	if ([syncStrategy isEqual:kWAArticleSyncDefaultStrategy]) {
	
		//	The default thing to do is to first get all the new stuff, then get all the changed stuff
		
		[self synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
		
			kWAArticleSyncFullyFetchStrategy, kWAArticleSyncStrategy,
		
		nil] completion:^(BOOL didFinish, NSError *error) {
		
			if (!didFinish) {
		
				if (completionBlock)
					completionBlock(didFinish, error);
			
				return;
				
			}
		
			[self synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
		
				kWAArticleSyncDeltaFetchStrategy, kWAArticleSyncStrategy,
			
			nil] completion:^(BOOL didFinish, NSError *error) {
			
				if (completionBlock)
					completionBlock(didFinish, error);
				
				if (didFinish)
					[[WADataStore defaultStore] setLastSyncSuccessDate:[NSDate date]];
				
			}];
			
		}];
		
		return;
	
	}
  
	if ([syncStrategy isEqual:kWAArticleSyncMergeLastBatchStrategy]) {

		//  Merging the last batch only, don’t care about the vaccum at all — this is less expensive but has the potential to leave lots of vacuum in the application

		[ri retrieveLatestPostsInGroup:usedGroupIdentifier withBatchLimit:usedBatchLimit onSuccess:^(NSArray *postReps) {

			[ds performBlock:^{

				NSManagedObjectContext *context = [ds disposableMOC];
				context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

				[[self class] insertOrUpdateObjectsUsingContext:context withRemoteResponse:postReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];

				NSError *savingError = nil;
				if ([context save:&savingError])
				NSLog(@"Error saving: %@", savingError);

				if (completionBlock)
					completionBlock(YES, nil);

			} waitUntilDone:NO];

			[ds setLastSyncSuccessDate:[NSDate date]];

		} onFailure:^(NSError *error) {

			if (completionBlock)
				completionBlock(NO, error);

		}];
    
	} else if ([syncStrategy isEqual:kWAArticleSyncFullyFetchStrategy]) {
		
		NSDate *usedDate = [ds lastNewPostsUpdateDate];
		if (!usedDate) {
			usedDate = [NSDate dateWithTimeIntervalSince1970:0];
		}
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		NSString *datum = [formatter stringFromDate:usedDate];
		NSDictionary *filterEntity = [NSDictionary dictionaryWithObjectsAndKeys:
																	@"100", @"limit",
																	datum, @"timestamp",
																	nil];

		[ri retrievePostsInGroup:usedGroupIdentifier usingFilter:filterEntity onSuccess:^(NSArray *postReps) {

			[ds performBlock:^{
				
				NSManagedObjectContext *context = [ds disposableMOC];
				
				NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:postReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
				
				/* Steven: we examin each touched article is really touched by checking its modifiedDate.
				 * If the modifiedDate is later then current lastNewPostsUpdateDate, then we update these articles.
				 * If not, don't change them. It won't cause a data store change, and won't cause the timeline refresh */
				BOOL changed = NO;
				NSMutableArray *newFiles = [[NSMutableArray alloc] init];
				for (WAArticle *article in touchedArticles) {
					NSComparisonResult dateComparison = [article.modificationDate compare:usedDate];
					if (usedDate && (dateComparison == NSOrderedSame || dateComparison == NSOrderedAscending))
						continue;
					changed = YES;
					if ([ds isUpdatingArticle:[[article objectID] URIRepresentation]]) {
						[context refreshObject:article mergeChanges:NO];
					} else {
						for (WAFile *file in article.files) {
							[newFiles addObject:file];
						}
					}
				}
				
				if (changed) {
					[context save:nil];
					// start downloading thumbnails for files of updated articles
					for (WAFile *file in newFiles) {
						[file smallThumbnailFilePath];
						[file thumbnailFilePath];
					}
				}
				
			} waitUntilDone:YES];
			
			NSDate *latestTimestamp = usedDate;
			
			for (NSDictionary *postRep in postReps) {
				NSDate *timestamp = [[WADataStore defaultStore] dateFromISO8601String:[postRep objectForKey:@"timestamp"]];
				latestTimestamp = [latestTimestamp laterDate:timestamp];
				NSCParameterAssert(latestTimestamp);
			}

			if (latestTimestamp) {
				[ds setLastNewPostsUpdateDate:latestTimestamp];
			}

			if (completionBlock)
				completionBlock(YES, nil);

		} onFailure:^(NSError *error) {

			if (completionBlock)
				completionBlock(NO, error);

		}];

  } else if ([syncStrategy isEqual:kWAArticleSyncDeltaFetchStrategy]) {
		
		NSDate *usedDate = [ds lastChangedPostsUpdateDate];
		
		[ri retrieveChangedArticlesSince:usedDate
														 inGroup:usedGroupIdentifier
													onProgress:^(NSArray *changedArticleReps, NSDate *continuation)
		 {
			 [ds performBlock:^{
				 NSManagedObjectContext *context = [ds disposableMOC];
				 
				 NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:changedArticleReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
				 
				 NSMutableArray *newFiles = [[NSMutableArray alloc] init];
				 for (WAArticle *article in touchedArticles) {
					 if ([ds isUpdatingArticle:[[article objectID] URIRepresentation]]) {
						 [context refreshObject:article mergeChanges:NO];
					 } else {
						 for (WAFile *file in article.files) {
							 [newFiles addObject:file];
						 }
					 }
				 }
				 
				 [context save:nil];
				 
				 // start downloading thumbnails for files of updated articles
				 for (WAFile *file in newFiles) {
					 [file smallThumbnailFilePath];
					 [file thumbnailFilePath];
				 }
			 }
					waitUntilDone:YES];
			 
			 if (continuation) {
				 [ds setLastChangedPostsUpdateDate:continuation];
			 }
		 }
													 onSuccess:^(NSDate *continuation) {
														 
														 if (continuation) {
															 [ds setLastChangedPostsUpdateDate:continuation];
														 }
														 
														 if (completionBlock)
															 completionBlock(YES, nil);
														 
													 }
													 onFailure:^(NSError *error) {
														 
														 if (completionBlock)
															 completionBlock(NO, error);
														 
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
		if (comparisonResult == NSOrderedDescending || comparisonResult == NSOrderedSame) {

			callback(WAArticleEntitySyncingError(1, @"Remote copy is newer, skipping sync", nil));

		} else {

			callback([NSValue valueWithBytes:&(NSComparisonResult){ comparisonResult } objCType:@encode(__typeof__(NSComparisonResult))]);

		}
		
	} completionBlock: ^ (id results) {
	
		NSCParameterAssert(results);
		
		if ([results isKindOfClass:[NSError class]]) {

			if ([[(NSError*)results domain] isEqualToString:kWAArticleEntitySyncingErrorDomain] &&
					[(NSError*)results code] == 1) {

				WADataStore *ds = [WADataStore defaultStore];
			
				[ds performBlock:^{

					NSManagedObjectContext *context = [ds disposableMOC];
					WAArticle *savedPost = (WAArticle *)[context irManagedObjectForURI:postEntityURL];
					savedPost.dirty = (id)kCFBooleanFalse;
					NSError *savingError = nil;
					[context save:&savingError];
				
				} waitUntilDone:NO];
			
			}
		}
	
	}]];
	
	
	[[self.files array] enumerateObjectsUsingBlock: ^ (WAFile *file, NSUInteger idx, BOOL *stop) {
	
		NSURL *aFileURL = [[file objectID] URIRepresentation];
	
		[operations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock: ^ (void(^aCallback)(id results)) {
		
			//	Re-fetch for clarity, use the shared MOC to avoid duplicating state, as long as we are careful NOT to mutate anything.
		
			NSManagedObjectContext *context = [[WADataStore defaultStore] newContextWithConcurrencyType:NSConfinementConcurrencyType];
			WAFile *representedFile = (WAFile *)[context irManagedObjectForURI:aFileURL];
			NSCParameterAssert(![representedFile hasChanges]);
			if (!representedFile) {
				aCallback(WAArticleEntitySyncingError(0, [NSString stringWithFormat:@"Unable to find WAFile entity at %@", aFileURL], nil));
				return;
			}
			
			if (representedFile.identifier) {
				aCallback(representedFile.identifier);
				return;
			}
			
			NSURL *fileURI = [[representedFile objectID] URIRepresentation];
			
			[representedFile synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
			
				kWAFileSyncReducedQualityStrategy, kWAFileSyncStrategy,
			
			nil] completion:^(BOOL didFinish, NSError *error) {
			
				if (!didFinish) {
					aCallback(error);
					return;
				}
			
				NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
				WAFile *savedFile = (WAFile *)[context irManagedObjectForURI:fileURI];
				
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

		[operations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock:^(IRAsyncOperationCallback callback) {

			[ri retrievePreviewForURL:previewURL onSuccess:^(NSDictionary *aPreviewRep) {

				callback(aPreviewRep);
				
			} onFailure:^(NSError *error) {
			
				callback(error);
				
			}];
		
		} completionBlock:^(id results) {
		
			NSCParameterAssert(results);
			
			if (![results isKindOfClass:[NSDictionary class]])
				return;
			
			WAArticle *savedPost = (WAArticle *)[[[WADataStore defaultStore] disposableMOC] irManagedObjectForURI:postEntityURL];
			WAPreview *savedPreview = [savedPost.previews anyObject];

			if ([savedPreview.graphElement.images count]) {
			
				NSMutableDictionary *previewEntity = [(NSDictionary *)results mutableCopy];

				// use the first preview image for thumbnail_url while creating posts
				if (isDraft) {
					[previewEntity setObject:[[[savedPreview.graphElement.images array] objectAtIndex:0] imageRemoteURL] forKey:@"thumbnail_url"];
				} else {
					NSString *thumbnailURL = savedPreview.graphElement.representingImage.imageRemoteURL;
					[previewEntity setObject:(thumbnailURL ? thumbnailURL : @"") forKey:@"thumbnail_url"];
				}

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

			if (!isHidden) {

				[ri createPostInGroup:groupID withContentText:postText attachments:attachments preview:preview createTime:postCreationDate updateTime:postModificationDate favorite:isFavorite onSuccess:^(NSDictionary *postRep) {
					
					callback(postRep);

				} onFailure: ^ (NSError *error) {

					callback(error);

				}];

			}

		} else {
			
			if (isHidden) {
				
				[ri configurePost:postID inGroup:groupID withVisibilityStatus:NO onSuccess:^{

					// FIXME: clear dirty flag of the article immediately after calling hide API
					// it's a workaround because the response and parameters of hide and update APIs are different.
					// still buggy and needs refactoring
					WADataStore *ds = [WADataStore defaultStore];

					[ds performBlock:^{

						NSManagedObjectContext *context = [ds disposableMOC];
						WAArticle *savedPost = (WAArticle *)[context irManagedObjectForURI:postEntityURL];
						savedPost.dirty = (id)kCFBooleanFalse;
						NSError *savingError = nil;
						BOOL didSave = [context save:&savingError];

						completionBlock(didSave, savingError);

					} waitUntilDone:NO];

				} onFailure:^(NSError *error) {

					callback(error);

				}];

			} else {

				NSDate *lastPostModDate = [context objectForKey:kPostExistingRemoteRepDate];
				
				[ri updatePost:postID inGroup:groupID withText:postText attachments:attachments mainAttachment:postCoverPhotoID preview:preview favorite:isFavorite hidden:isHidden replacingDataWithDate:lastPostModDate updateTime:postModificationDate onSuccess:^(NSDictionary *postRep) {

					callback(postRep);

				} onFailure:^(NSError *error) {

					callback(error);

				}];

			}
		
		}
		
	} completionBlock:^(id results) {
	
		NSCParameterAssert(results);
		
		if ([results isKindOfClass:[NSDictionary class]]) {
		
			WADataStore *ds = [WADataStore defaultStore];
			
			[ds performBlock:^{
				
				NSManagedObjectContext *context = [ds disposableMOC];
				context.mergePolicy = NSOverwriteMergePolicy;
				
				WAArticle *savedPost = (WAArticle *)[context irManagedObjectForURI:postEntityURL];
				savedPost.draft = (id)kCFBooleanFalse;
				
				NSDictionary * const mapping = [WAArticle remoteDictionaryConfigurationMapping];
				id (^valueForMappingKey)(NSString *) = ^ (NSString *hostKey) {
					NSString *networkKey = [[mapping allKeysForObject:hostKey] lastObject];
					return [[self class] transformedValue:[results objectForKey:networkKey] fromRemoteKeyPath:networkKey toLocalKeyPath:hostKey];
				};
				
				if (!savedPost.identifier)
					savedPost.identifier = valueForMappingKey(@"identifier");
				
				NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObject:results] usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
				NSCParameterAssert([touchedArticles containsObject:savedPost] && ([touchedArticles count] == 1));
				
				NSDate *remoteModDate = valueForMappingKey(@"modificationDate");	//	FIXME: may NOT have it
				NSDate *localModDate = savedPost.modificationDate;
				
				NSCParameterAssert([remoteModDate isKindOfClass:[NSDate class]] && [localModDate isKindOfClass:[NSDate class]]);
				if ([remoteModDate isEqualToDate:localModDate]) {
					savedPost.dirty = (id)kCFBooleanFalse;
					NSLog(@"post %@ is saved, and not dirty any more; it does not need further syncing", savedPost);
				} else {
					NSLog(@"post %@ is saved but needs additional syncing", savedPost);
					[context refreshObject:savedPost mergeChanges:NO];	//	throw away remote changes awaiting new sync resolution
				}
				
				NSError *savingError = nil;
				BOOL didSave = [context save:&savingError];
				
				completionBlock(didSave, savingError);
			
			} waitUntilDone:NO];
		
		} else {
		
			NSError *error = (NSError *)([results isKindOfClass:[NSError class]] ? results : nil);
			completionBlock(NO, error);
			
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
