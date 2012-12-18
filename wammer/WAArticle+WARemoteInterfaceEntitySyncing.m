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
#import "WADefines.h"
#import "WAAppDelegate_iOS.h"
#import "NSDate+WAAdditions.h"
#import <NSDate+SSToolkitAdditions.h>


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
    
		mapping = @{
		@"post_id": @"identifier",
		@"group": @"group",	//	wraps @"group_id"
		@"owner": @"owner",	//	wraps @"creator_id"
		@"attachments": @"files",
		@"previews": @"previews",
		@"representingFile": @"representingFile",	//	wraps @"cover_attach"
		@"code_name": @"creationDeviceName",
		@"timestamp": @"creationDate",
		@"eventDay": @"eventDay",
		@"update_time": @"modificationDate",
		@"content": @"text",
		@"comments": @"comments",
		@"soul": @"summary",
		@"favorite": @"favorite",
		@"hidden": @"hidden",
		@"style": @"style",
		@"import": @"import",
		@"event_tag": @"event",
		@"tags": @"tags",
		@"gps": @"location",
		@"checkins": @"checkins",
		@"people": @"people",
		@"extra_parameters": @"descriptiveTags",
		@"event_description": @"eventDescription",
		};
		
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
		return (![aValue isEqual:@"false"] && ![aValue isEqual:@"0"] && ![aValue isEqual:@0]) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;
	
	if ([aLocalKeyPath isEqualToString:@"hidden"])
		return (![aValue isEqual:@"false"] && ![aValue isEqual:@"0"] && ![aValue isEqual:@0]) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	return @{@"group": @"WAGroup",
		@"comments": @"WAComment",
		@"owner": @"WAUser",
		@"previews": @"WAPreview",
		@"attachments": @"WAFile",
		@"representingFile": @"WAFile",
		@"gps": @"WALocation",
		@"people": @"WAPeople",
		@"checkins": @"WALocation",
		@"tags": @"WATag",
	  @"eventDay": @"WAEventDay",
		@"extra_parameters": @"WATagGroup"};

}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSMutableDictionary *returnedDictionary = [incomingRepresentation mutableCopy];

	NSString *creatorID = incomingRepresentation[@"creator_id"];
	NSString *articleID = incomingRepresentation[@"post_id"];
	NSString *groupID = incomingRepresentation[@"group_id"];
	NSString *representingFileID = incomingRepresentation[@"cover_attach"];
	NSString *type = incomingRepresentation[@"type"];

	NSMutableArray *fullAttachmentList = [incomingRepresentation[@"attachment_id_array"] mutableCopy];
	NSArray *incomingAttachmentList = [incomingRepresentation[@"attachments"] copy];
	NSMutableArray *returnedAttachmentList = [incomingAttachmentList mutableCopy];
	if (!returnedAttachmentList) {
		returnedAttachmentList = [[NSMutableArray alloc] init];
	}

	if ([fullAttachmentList count] > [incomingAttachmentList count]) {

		// dedup
		for (NSDictionary *attachment in incomingAttachmentList) {
			[fullAttachmentList removeObject:attachment[@"object_id"]];
		}

		for (NSString *objectID in fullAttachmentList) {
			NSMutableDictionary *attach = [@{
				@"object_id": objectID,
				@"creator_id": creatorID,
				@"post_id": articleID,
				@"outdated": @YES,
			} mutableCopy];
			if ([type isEqualToString:@"image"]) {
				attach[@"type"] = @"image";
			} else if ([type isEqualToString:@"doc"]) {
				attach[@"type"] = @"doc";
			}
			[returnedAttachmentList addObject:attach];
		}

		returnedDictionary[@"attachments"] = returnedAttachmentList;

	}

	if ([creatorID length])
		returnedDictionary[@"owner"] = @{@"user_id": creatorID};

	if ([groupID length])
		returnedDictionary[@"group"] = @{@"group_id": groupID};
	
	if ([representingFileID length])
		returnedDictionary[@"representingFile"] = @{@"object_id": representingFileID};
	
	NSArray *comments = incomingRepresentation[@"comments"];
	if ([comments count] && articleID) {
	
		NSMutableArray *transformedComments = [comments mutableCopy];
		
		[comments enumerateObjectsUsingBlock: ^ (NSDictionary *aCommentRep, NSUInteger idx, BOOL *stop) {
		
			NSMutableDictionary *transformedComment = [aCommentRep mutableCopy];
			NSString *commentID = transformedComment[@"comment_id"];
			id aTimestamp = aCommentRep[@"timestamp"];
			if (!aTimestamp)
				aTimestamp = IRWebAPIKitNonce();
			
			if (!commentID) {
				commentID = [NSString stringWithFormat:@"Synthesized_Article_%@_Timestamp_%@", articleID, aTimestamp];
				transformedComment[@"comment_id"] = commentID;
			}
			
			transformedComments[idx] = transformedComment;
			
		}];
		
		returnedDictionary[@"comments"] = transformedComments;
	
	}
	
	NSArray *people = incomingRepresentation[@"people"];
	if (!people || people.count == 0) {
		[returnedDictionary removeObjectForKey:@"people"];
	}
	
	NSArray *tags = incomingRepresentation[@"tags"];
	if ([tags count]) {
		
		NSMutableArray *transformedTags = [NSMutableArray arrayWithCapacity:[tags count]];
		[tags enumerateObjectsUsingBlock:^(NSString *aTagRep, NSUInteger idx, BOOL *stop) {
			[transformedTags addObject:@{@"tagValue": aTagRep}];
		}];
		
		returnedDictionary[@"tags"] = transformedTags;
	}
		
	NSDictionary *preview = incomingRepresentation[@"preview"];
	
	if ([preview count]) {
	
		returnedDictionary[@"previews"] = @[@{@"og": preview,
				@"id": [preview valueForKeyPath:@"url"]}];
	
	}
		
	
	if ([incomingRepresentation[@"import"] isEqualToString:@"true"]) {
		NSString *deviceID = incomingRepresentation[@"device_id"];
		if ([deviceID isEqualToString:WADeviceIdentifier()]) {
			[returnedDictionary setValue:@(WAImportTypeFromLocal) forKey:@"import"];
		} else {
			[returnedDictionary setValue:@(WAImportTypeFromOthers) forKey:@"import"];
		}
	} else {
		[returnedDictionary setValue:@(WAImportTypeNone) forKey:@"import"];
	}

	if ([incomingRepresentation[@"event_tag"] isEqualToString:@"true"]) {
		[returnedDictionary setValue:@YES forKey:@"event_tag"];
	} else {
		[returnedDictionary setValue:@NO forKey:@"event_tag"];
	}

	NSString *timestamp = incomingRepresentation[@"timestamp"];
	if (timestamp && [returnedDictionary[@"event_tag"] isEqual:@YES]) {					// It is an event, we record its event day

		[returnedDictionary setValue:@{@"day" : [[NSDate dateFromISO8601String:timestamp] dayBegin]}
													forKey:@"eventDay"];

	}
	
	return returnedDictionary;

}

+ (void) synchronizeWithCompletion:(void (^)(BOOL, NSError *))completionBlock {

  [self synchronizeWithOptions:@{kWAArticleSyncStrategy: kWAArticleSyncDefaultStrategy} completion:completionBlock];

}

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(void (^)(BOOL, NSError *))completionBlock {

	WAArticleSyncStrategy wantedStrategy = options[kWAArticleSyncStrategy];
	WAArticleSyncStrategy syncStrategy = wantedStrategy;
	
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	WADataStore *ds = [WADataStore defaultStore];
	NSString *usedGroupIdentifier = ri.primaryGroupIdentifier;
	NSUInteger usedBatchLimit = ri.defaultBatchSize;
	
	if (!usedGroupIdentifier) {
		completionBlock(NO, [NSError errorWithDomain:@"com.waveface.wammer.dataStore.article" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Article sync requires a primary group identifier"}]);
		return;
	}
	
	if ([syncStrategy isEqual:kWAArticleSyncDefaultStrategy]) {
	
		//	The default thing to do is to first get all the new stuff, then get all the changed stuff
		
		[self synchronizeWithOptions:@{kWAArticleSyncStrategy: kWAArticleSyncFullyFetchStrategy} completion:^(BOOL didFinish, NSError *error) {
		
			if (!didFinish) {
		
				if (completionBlock)
					completionBlock(didFinish, error);
			
				return;
				
			}
		
			[self synchronizeWithOptions:@{kWAArticleSyncStrategy: kWAArticleSyncDeltaFetchStrategy} completion:^(BOOL didFinish, NSError *error) {
			
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

				NSManagedObjectContext *context = [ds autoUpdatingMOC];
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
		NSDictionary *filterEntity = @{@"limit": @(usedBatchLimit),
																	@"timestamp": datum};

		[ri retrievePostsInGroup:usedGroupIdentifier usingFilter:filterEntity onSuccess:^(NSArray *postReps) {

			[ds performBlock:^{
				
				NSManagedObjectContext *context = [ds autoUpdatingMOC];
				
				NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:postReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
				
				/* Steven: we examin each touched article is really touched by checking its modifiedDate.
				 * If the modifiedDate is later then current lastNewPostsUpdateDate, then we update these articles.
				 * If not, don't change them. It won't cause a data store change, and won't cause the timeline refresh */
				__block BOOL changed = NO;
				[touchedArticles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

					WAArticle *article = obj;
					NSComparisonResult dateComparison = [article.modificationDate compare:usedDate];
					if (!usedDate || dateComparison == NSOrderedDescending) {

						changed = YES;

						if ([ds isUpdatingArticle:[[article objectID] URIRepresentation]]) {
							[context refreshObject:article mergeChanges:NO];
						}

					}

				}];
				
				if (changed) {
					[context save:nil];
				}
				
			} waitUntilDone:YES];
			
			NSDate *latestTimestamp = usedDate;
			
			for (NSDictionary *postRep in postReps) {
				NSDate *timestamp = [[WADataStore defaultStore] dateFromISO8601String:postRep[@"timestamp"]];
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
		
		[ri retrieveChangesSince:usedDate
														 inGroup:usedGroupIdentifier
													onProgress:^(NSArray *changedArticleReps, NSDate *continuation)
		 {
			 [ds performBlock:^{
				 NSManagedObjectContext *context = [ds autoUpdatingMOC];
				 
				 NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:changedArticleReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
				 
				 [touchedArticles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

					 WAArticle *article = obj;
					 NSComparisonResult dateComparison = [article.modificationDate compare:usedDate];
					 if (!usedDate || dateComparison == NSOrderedDescending) {

						 if ([ds isUpdatingArticle:[[article objectID] URIRepresentation]]) {
							 [context refreshObject:article mergeChanges:NO];
						 }
						 
					 }

				 }];
				 
				 [context save:nil];
				 
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

	id mergePolicy = options[WAMergePolicyKey];
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
	
	BOOL isDraft = ([self.draft isEqualToNumber:(id)kCFBooleanTrue] || !self.identifier || !self.modificationDate);
	BOOL isFavorite = [self.favorite isEqualToNumber:(id)kCFBooleanTrue];
	BOOL isHidden = [self.hidden isEqualToNumber:(id)kCFBooleanTrue];
	BOOL isImport = [self.import isEqualToNumber:@(WAImportTypeFromLocal)];
	
	if (!isDraft) {
	
		[operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

			[ri retrievePost:postID inGroup:groupID onSuccess:^(NSDictionary *postRep) {
				
				callback(postRep);
				
			} onFailure:^(NSError *error) {
				
				callback(error);
				
			}];

		} trampoline:^(IRAsyncOperationInvoker callback) {

			callback();
		
		} callback:^(id results) {

			if ([results isKindOfClass:[NSDictionary class]]) {
				context[kPostExistingRemoteRep] = results;
			}

		} callbackTrampoline:^(IRAsyncOperationInvoker callback) {

			callback();

		}]];
	
	}
	
	
	[operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

		NSDictionary *postExistingRemoteRep = context[kPostExistingRemoteRep];
		if (!postExistingRemoteRep) {
			callback((id)kCFBooleanTrue);
			return;
		}
		
		//	Compare timestamp, return boxed nscomparisonresult
		
		NSDictionary *mapping = [WAArticle remoteDictionaryConfigurationMapping];
		
		id (^mappedValue)(NSString *) = ^ (NSString *localKeyPath) {
			
			NSString *remoteKeyPath = [[mapping allKeysForObject:localKeyPath] lastObject];	//	Assumed that there will only be one key pointing to this object
			id remoteValue = postExistingRemoteRep[remoteKeyPath];
			
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
		
		context[kPostExistingRemoteRepDate] = remoteDate;
		context[kPostLocalModDate] = localDate;
		
		NSComparisonResult comparisonResult = [remoteDate compare:localDate];
		if (comparisonResult == NSOrderedDescending || comparisonResult == NSOrderedSame) {
			
			callback(WAArticleEntitySyncingError(1, @"Remote copy is newer, skipping sync", nil));
			
		} else {
			
			callback([NSValue valueWithBytes:&(NSComparisonResult){ comparisonResult } objCType:@encode(__typeof__(NSComparisonResult))]);
			
		}

	} trampoline:^(IRAsyncOperationInvoker callback) {

		callback();
	
	} callback:^(id results) {

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
	
	} callbackTrampoline:^(IRAsyncOperationInvoker callback) {

		callback();

	}]];
	
	[[self.files array] enumerateObjectsUsingBlock: ^ (WAFile *file, NSUInteger idx, BOOL *stop) {
	
		NSURL *aFileURL = [[file objectID] URIRepresentation];
	
		[operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

			NSManagedObjectContext *context = [[WADataStore defaultStore] newContextWithConcurrencyType:NSConfinementConcurrencyType];
			WAFile *representedFile = (WAFile *)[context irManagedObjectForURI:aFileURL];
			NSCParameterAssert(![representedFile hasChanges]);
			if (!representedFile) {
				callback(WAArticleEntitySyncingError(0, [NSString stringWithFormat:@"Unable to find WAFile entity at %@", aFileURL], nil));
				return;
			}
			
			if (representedFile.identifier && (representedFile.thumbnailURL || representedFile.resourceURL)) {
				callback(representedFile.identifier);
				return;
			}
			
			NSURL *fileURI = [[representedFile objectID] URIRepresentation];
			NSString *fileSyncStrategy = [ri hasReachableStation] ? kWAFileSyncFullQualityStrategy : kWAFileSyncReducedQualityStrategy;
			
			[representedFile synchronizeWithOptions:@{kWAFileSyncStrategy: fileSyncStrategy} completion:^(BOOL didFinish, NSError *error) {
				
				if (!didFinish) {
					callback(error);
					return;
				}
				
				NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
				WAFile *savedFile = (WAFile *)[context irManagedObjectForURI:fileURI];
				
				NSCParameterAssert(savedFile.articles);
				NSCParameterAssert(savedFile.identifier);
				callback(savedFile.identifier);
				
			}];

		} trampoline:^(IRAsyncOperationInvoker callback) {

			callback();

		} callback:^(id results) {

			if (![results isKindOfClass:[NSString class]])
				return;
			
			NSMutableArray *attachmentIDs = context[kPostAttachmentIDs];
			if (!attachmentIDs) {
				attachmentIDs = [NSMutableArray array];
				context[kPostAttachmentIDs] = attachmentIDs;
			}
			
			NSParameterAssert([attachmentIDs isKindOfClass:[NSMutableArray class]]);
			[attachmentIDs addObject:results];
			
			[(WAAppDelegate_iOS *)AppDelegate() syncManager].syncedFilesCount += 1;

		} callbackTrampoline:^(IRAsyncOperationInvoker callback) {

			callback();

		}]];

		[(WAAppDelegate_iOS *)AppDelegate() syncManager].needingSyncFilesCount += 1;
		
	}];
	
	
	WAPreview * const anyPreview = [self.previews anyObject];
	NSString * const previewURLString = (anyPreview.graphElement.url ? anyPreview.graphElement.url : anyPreview.url);
	NSURL * const previewURL = previewURLString ? [NSURL URLWithString:previewURLString] : nil;
	
	if (previewURL) {

		[operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

			[ri retrievePreviewForURL:previewURL onSuccess:^(NSDictionary *aPreviewRep) {
				
				callback(aPreviewRep);
				
			} onFailure:^(NSError *error) {
				
				callback(error);
				
			}];

		} trampoline:^(IRAsyncOperationInvoker callback) {

			callback();
		
		} callback:^(id results) {

			NSCParameterAssert(results);
			
			if (![results isKindOfClass:[NSDictionary class]])
				return;
			
			WAArticle *savedPost = (WAArticle *)[[[WADataStore defaultStore] disposableMOC] irManagedObjectForURI:postEntityURL];
			WAPreview *savedPreview = [savedPost.previews anyObject];
			
			if ([savedPreview.graphElement.images count]) {
				
				NSMutableDictionary *previewEntity = [(NSDictionary *)results mutableCopy];
				
				// use the first preview image for thumbnail_url while creating posts
				if (isDraft) {
					previewEntity[@"thumbnail_url"] = [[savedPreview.graphElement.images array][0] imageRemoteURL];
				} else {
					NSString *thumbnailURL = savedPreview.graphElement.representingImage.imageRemoteURL;
					previewEntity[@"thumbnail_url"] = (thumbnailURL ? thumbnailURL : @"");
				}
				
				context[kPostWebPreview] = previewEntity;
				
			} else {
				
				context[kPostWebPreview] = results;
				
			}

		} callbackTrampoline:^(IRAsyncOperationInvoker callback) {

			callback();
		
		}]];
	
	}
	
	
	[operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

		NSArray *attachments = context[kPostAttachmentIDs];
		NSDictionary *preview = context[kPostWebPreview];
		
		if (isDraft) {
			
			if (!isHidden) {
				
				[ri createPostInGroup:groupID withContentText:postText attachments:attachments preview:preview postId:postID createTime:postCreationDate updateTime:postModificationDate favorite:isFavorite import:isImport onSuccess:^(NSDictionary *postRep) {
					
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
				
				NSDate *lastPostModDate = context[kPostExistingRemoteRepDate];
				
				[ri updatePost:postID inGroup:groupID withText:postText attachments:attachments mainAttachment:postCoverPhotoID preview:preview favorite:isFavorite hidden:isHidden replacingDataWithDate:lastPostModDate updateTime:postModificationDate onSuccess:^(NSDictionary *postRep) {
					
					callback(postRep);
					
				} onFailure:^(NSError *error) {
					
					callback(error);
					
				}];
				
			}
			
		}

	} trampoline:^(IRAsyncOperationInvoker callback) {

		callback();
	
	} callback:^(id results) {

		NSCParameterAssert(results);
		
		
		void (^dismissSyncStatusBarIfNeeded)(BOOL forced) = ^(BOOL forced) {
			
			WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
			
			if (forced) {
				
				if (!syncManager.syncStopped) {
					
					[syncManager resetSyncFilesCount];
					
				}
				
			} else {
				
				if (syncManager.syncCompleted) {
					
					[syncManager resetSyncFilesCount];
					
				}
				
			}
			
		};
		
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
					return [[self class] transformedValue:results[networkKey] fromRemoteKeyPath:networkKey toLocalKeyPath:hostKey];
				};
				
				if (!savedPost.identifier)
					savedPost.identifier = valueForMappingKey(@"identifier");
				
				NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:@[results] usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
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
				
				dismissSyncStatusBarIfNeeded(NO);
				
			} waitUntilDone:NO];
			
		} else {
			
			NSError *error = (NSError *)([results isKindOfClass:[NSError class]] ? results : nil);
			
			// post id already exists
			if ([[error domain] isEqualToString:kWARemoteInterfaceDomain] && [error code] == 0x3000 + 25) {
				NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
				context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
				WAArticle *savedPost = (WAArticle *)[context irManagedObjectForURI:postEntityURL];
				CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
				if (theUUID) {
					savedPost.identifier = [((__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID)) lowercaseString];
				}
				CFRelease(theUUID);
				[context save:nil];
			}
			
			completionBlock(NO, error);
			
			dismissSyncStatusBarIfNeeded(YES);
			
		}

	} callbackTrampoline:^(IRAsyncOperationInvoker callback) {

		callback();
	
	}]];	
	
	[operations enumerateObjectsUsingBlock: ^ (IRAsyncBarrierOperation *operation, NSUInteger idx, BOOL *stop) {
	
		if (idx > 0)
			[operation addDependency:operations[(idx - 1)]];
		
	}];
	
	IRAsyncOperation *lastOperation = [[[[self class] sharedSyncQueue] operations] lastObject];
	if (lastOperation) {
		[operations[0] addDependency:lastOperation];
	}
	
	[[[self class] sharedSyncQueue] addOperations:operations waitUntilFinished:NO];

}

+ (NSOperationQueue *) sharedSyncQueue {
	
	static NSOperationQueue *queue = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		queue = [[NSOperationQueue alloc] init];
		queue.maxConcurrentOperationCount = 1;
		
	});
	
	return queue;
	
}

@end
