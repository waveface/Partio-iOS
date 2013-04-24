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
#import "WACheckin.h"
#import "WAAppDelegate_iOS.h"
#import "NSDate+WAAdditions.h"
#import <NSDate+SSToolkitAdditions.h>
#import <SSToolkit/NSString+SSToolkitAdditions.h>
#import "WASyncManager.h"


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
    @"representingFile": @"representingFile",	//	wraps @"cover_attach"
    @"code_name": @"creationDeviceName",
    @"timestamp": @"creationDate",
    @"eventDay": @"eventDay",
    @"update_time": @"modificationDate",
	@"event_start_time": @"eventStartDate",
	@"event_end_time": @"eventEndDate",
    @"content": @"text",
	@"content_auto": @"textAuto",
    @"favorite": @"favorite",
    @"hidden": @"hidden",
	@"eventType": @"eventType",
    @"event": @"event",
    @"tags": @"tags",
    @"gps": @"location",
    @"checkins": @"checkins",
    @"people": @"people",
    @"shared_users": @"sharingContacts",
    @"extra_parameters": @"descriptiveTags",
    };
    
  });
  
  return mapping;
  
}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {
  
  if ([aLocalKeyPath isEqualToString:@"creationDate"])
    return [NSDate dateFromISO8601String:aValue ];
  
  if ([aLocalKeyPath isEqualToString:@"eventStartDate"])
	return [NSDate dateFromISO8601String:aValue];
  
  if ([aLocalKeyPath isEqualToString:@"eventEndDate"])
	return [NSDate dateFromISO8601String:aValue];
  
  if ([aLocalKeyPath isEqualToString:@"modificationDate"])
    return [NSDate dateFromISO8601String:aValue];
  
  if ([aLocalKeyPath isEqualToString:@"identifier"])
    return IRWebAPIKitStringValue(aValue);
  
  if ([aLocalKeyPath isEqualToString:@"favorite"])
    return (![aValue isEqual:@"false"] && ![aValue isEqual:@"0"] && ![aValue isEqual:@0]) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse;
    
  return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];
  
}

+ (NSDictionary *) defaultHierarchicalEntityMapping {
  
  return @{@"group": @"WAGroup",
  @"owner": @"WAUser",
  @"attachments": @"WAFile",
  @"representingFile": @"WAFile",
  @"gps": @"WALocation",
  @"people": @"WAPeople",
           @"shared_users": @"WAPeople",
  @"checkins": @"WACheckin",
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
  
  if ([type isEqualToString:@"event"]) {
	[returnedDictionary setValue:@YES forKey:@"event"];
  } else {
	[returnedDictionary setValue:@NO forKey:@"event"];
  }
    
  if ([incomingRepresentation[@"event_type"] isEqualToString:@"photo"]) {
	[returnedDictionary setValue:@(WAEventArticlePhotoType) forKey:@"eventType"];
  } else if ([incomingRepresentation[@"event_type"] isEqualToString:@"shared"]) {
    [returnedDictionary setValue:@(WAEventArticleSharedType) forKey:@"eventType"];
  }
  
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
//      if ([type isEqualToString:@"image"]) {
//        attach[@"type"] = @"image";
//      } else if ([type isEqualToString:@"doc"]) {
//        attach[@"type"] = @"doc";
//      }
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
  
  NSArray *people = incomingRepresentation[@"people"];
  if (!people || people.count == 0) {
    [returnedDictionary removeObjectForKey:@"people"];
  }
  
  NSArray *sharedPeople = incomingRepresentation[@"shared_users"];
  if (!sharedPeople.count) {
    [returnedDictionary removeObjectForKey:@"shared_users"];
  } else {
    NSLog(@"shared_users: %@", sharedPeople);
  }
  
  NSArray *tags = incomingRepresentation[@"tags"];
  if ([tags count]) {
    
    NSMutableArray *transformedTags = [NSMutableArray arrayWithCapacity:[tags count]];
    [tags enumerateObjectsUsingBlock:^(NSString *aTagRep, NSUInteger idx, BOOL *stop) {
      [transformedTags addObject:@{@"tagValue": aTagRep}];
    }];
    
    returnedDictionary[@"tags"] = transformedTags;
  }
  
//  NSString *event_start_time = incomingRepresentation[@"event_start_time"];
//  if (event_start_time && ![event_start_time isKindOfClass:[NSNull class]] &&[returnedDictionary[@"event"] isEqual:@YES]) {					// It is an event, we record its event day
//    
//    [returnedDictionary setValue:@{@"day" : [[NSDate dateFromISO8601String:event_start_time] dayBegin]}
//		      forKey:@"eventDay"];
//    
//  }
  
  return returnedDictionary;
  
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
  NSString * const kPostAttachmentIDs = @"postAttachmentIDs";
  NSString * const kPostLocalModDate = @"postLocalModDate";
  
  NSURL * const postEntityURL = [[self objectID] URIRepresentation];
  NSString * const postID = self.identifier;
  NSString * const postText = self.text;
  NSString * const groupID = self.group.identifier ? self.group.identifier : ri.primaryGroupIdentifier;
  NSString * const postCoverPhotoID = self.representingFile.identifier;
  NSDate * const postCreationDate = self.creationDate;
  NSDate * const postModificationDate = self.modificationDate;
  NSDate * const eventStartTime = self.eventStartDate;
  NSDate * const eventEndTime = self.eventEndDate;
  NSArray * invitingEmails = [(NSSet*)[self.sharingContacts valueForKey:@"email"] allObjects];
  WAEventArticleType eventType = [self.eventType intValue];
  
  NSMutableDictionary *postLocation = nil;
  if (self.location) {
    postLocation = [NSMutableDictionary dictionary];
    if (self.location.name)
      postLocation[@"name"] = self.location.name;
    
    if (self.location.latitude && self.location.longitude) {
      postLocation[@"latitude"] = self.location.latitude;
      postLocation[@"longitude"] = self.location.longitude;
    }
    
    if (self.tags) {
      NSMutableArray *tags = [NSMutableArray array];
      for (WATag *tag in self.tags) {
        [tags addObject:tag.tagValue];
      }
      postLocation[@"tags"] = [NSArray arrayWithArray:tags];
    }
  }
  
  NSMutableArray *postCheckins = nil;
  if (self.checkins.count) {
    postCheckins = [NSMutableArray array];
    for (WACheckin *checkin in self.checkins) {
      NSMutableDictionary *dict = [NSMutableDictionary dictionary];
      if (checkin.name)
        dict[@"name"] = checkin.name;
      if (checkin.latitude)
        dict[@"latitude"] = checkin.latitude;
      if (checkin.longitude)
        dict[@"longitude"] = checkin.longitude;
      [postCheckins addObject:dict];
    }
  }
  
  BOOL isDraft = ([self.draft isEqualToNumber:(id)kCFBooleanTrue] || !self.identifier || !self.modificationDate);
  BOOL isFavorite = [self.favorite isEqualToNumber:(id)kCFBooleanTrue];
  BOOL isHidden = [self.hidden isEqualToNumber:(id)kCFBooleanTrue];
  BOOL isEvent = [self.event isEqualToNumber:(id)kCFBooleanTrue];
  BOOL isSharedEvent = [self.eventType isEqualToNumber:[NSNumber numberWithInt:WAEventArticleSharedType]];
  
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
        
        WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
        syncManager.syncedFilesCount += 1;

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
      
      NSCParameterAssert([attachmentIDs isKindOfClass:[NSMutableArray class]]);
      [attachmentIDs addObject:results];
      
    } callbackTrampoline:^(IRAsyncOperationInvoker callback) {
      
      callback();
      
    }]];
    
  }];
  
  
  [operations addObject:[IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
    
    NSArray *attachments = context[kPostAttachmentIDs];
    
    if (isDraft) {
      
      if (!isHidden) {
        
        [ri createPostInGroup:groupID
			  withContentText:postText
				  attachments:attachments
						 type:isEvent?(isSharedEvent?WAArticleTypeSharedEvent:WAArticleTypeEvent):WAArticleTypeImport
                    eventType:isEvent?eventType:WAEventArticleUnknownType
					   postId:postID
				   createTime:postCreationDate
				   updateTime:postModificationDate
               eventStartTime:eventStartTime
                 eventEndTime:eventEndTime
					 favorite:isFavorite
               invitingEmails:invitingEmails
                     location:postLocation
                     checkins:postCheckins
					onSuccess:^(NSDictionary *postRep) {
	
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
        
        [ri updatePost:postID
			   inGroup:groupID
			  withText:postText
		   attachments:attachments
		mainAttachment:postCoverPhotoID
				  type:isEvent?(isSharedEvent?WAArticleTypeSharedEvent:WAArticleTypeEvent):WAArticleTypeImport
             eventType:isEvent?eventType:WAEventArticleUnknownType
			  favorite:isFavorite
				hidden:isHidden
 replacingDataWithDate:lastPostModDate
			updateTime:postModificationDate
        eventStartTime:eventStartTime
          eventEndTime:eventEndTime
        invitingEmails:invitingEmails
              location:postLocation
              checkins:postCheckins
			 onSuccess:^(NSDictionary *postRep) {
	
			   callback(postRep);
	
        } onFailure:^(NSError *error) {
	
		  callback(error);
	
        }];
        
      }
      
    }
    
  } trampoline:^(IRAsyncOperationInvoker callback) {
    
    callback();
    
  } callback:^(id results) {
    
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
        
      } waitUntilDone:NO];
      
    } else {
      
      // results will be nil if this operation is canceled
      NSError *error = (NSError *)([results isKindOfClass:[NSError class]] ? results : nil);

      if (error) {

        // post id already exists. Mostly the post has successfully been created but local DB has not been updated (ex. crash)
        if ([[error domain] isEqualToString:kWARemoteInterfaceDomain] && [error code] == 0x3000 + 25) {

		  NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		  context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		  WAArticle *savedPost = (WAArticle *)[context irManagedObjectForURI:postEntityURL];
		  savedPost.draft = @NO;
		  savedPost.dirty = @NO;
	
		  completionBlock([context save:nil], nil);
 
        } else {
	
		  WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
		  syncManager.isSyncFail = YES;

		  completionBlock(NO, error);

        }
        
      } else {

        completionBlock(YES, nil);

      }

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
