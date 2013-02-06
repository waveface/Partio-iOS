//
//  WAFetchManager+RemoteArticleFetch.m
//  wammer
//
//  Created by kchiu on 12/12/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFetchManager+RemoteIndexFetch.h"
#import "Foundation+IRAdditions.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WADefines.h"

@implementation WAFetchManager (RemoteIndexFetch)

- (IRAsyncOperation *)remoteIndexFetchOperationPrototype {

  __weak WAFetchManager *wSelf = self;

  IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
    
    if (![wSelf canPerformArticleFetch]) {
      callback(nil);
      return;
    }

    [wSelf beginPostponingFetch];

	WADataStore *ds = [WADataStore defaultStore];
	NSNumber *currentSeq = [ds minSequenceNumber];
	if (!currentSeq) {
	  currentSeq = @(INT_MAX);
	  
	  WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	  [ri retrievePostsInGroup:ri.primaryGroupIdentifier usingSequenceNumber:currentSeq withLimit:@(-10) onSuccess:^(NSArray *postReps, NSNumber *remainingCount, NSNumber*nextSeq) {
		  
		[ds performBlock:^{
	
		  NSManagedObjectContext *context = [ds autoUpdatingMOC];
		  
		  NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:postReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
	
		  // restore articles in updating
		  for (WAArticle *article in touchedArticles) {
			if ([ds isUpdatingArticle:[[article objectID] URIRepresentation]]) {
			  [context refreshObject:article mergeChanges:NO];
			}
		  }
		  
		  [context save:nil];
		  
		} waitUntilDone:YES];
		  
		if ([remainingCount integerValue] == 0) {
		  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAFirstArticleFetched];
		  [[NSUserDefaults standardUserDefaults] synchronize];
		}
        
		if (![ds maxSequenceNumber]) {
		  if ([postReps count]) {
			NSNumber *maxSeq = @0;
			for (NSDictionary *post in postReps) {
			  if ([post[@"seq_num"] integerValue] > [maxSeq integerValue]) {
				maxSeq = post[@"seq_num"];
			  }
			}
			[ds setMaxSequenceNumber:@([maxSeq integerValue]+1)];
		  }
		}
		
		[ds setMinSequenceNumber:nextSeq];

		[wSelf endPostponingFetch];
        
		callback(nil);

	  } onFailure:^(NSError *error) {
		
		[wSelf endPostponingFetch];

		callback(error);

	  }];
		
	} else {// if (currentSeq)
		
	  WADataStore *ds = [WADataStore defaultStore];
	  NSDate *currentFetchedDate = [ds earliestDate];
	  if (!currentFetchedDate)
		currentFetchedDate = [NSDate date];
	  
	  WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	  
	  NSInteger offsetDays = -30;
	  [ri retrieveSummariesSince:currentFetchedDate
					  daysOffset:offsetDays
						 inGroup:ri.primaryGroupIdentifier
					   onSuccess:^(NSArray *summaries, BOOL hasMore) {
						 
						 NSMutableArray *toFetchPostIdList = [NSMutableArray array];
						 NSMutableArray *toFetchImageIdList = [NSMutableArray array];
						 for (NSDictionary *entry in summaries) {
						   
						   NSArray *eventIDList = [entry valueForKey:@"event_id_list"];
						   NSArray *imageIdList = [entry valueForKey:@"image_id_list"];
						   NSArray *docIdList = [entry valueForKey:@"doc_id_list"];
						   NSArray *webthumbIdList = [entry valueForKey:@"webthumb_id_list"];
						   
						   if ([eventIDList count]) {
							 [toFetchPostIdList addObjectsFromArray:eventIDList];
						   }
						   
						   if ([imageIdList count]) {
							 [toFetchImageIdList addObjectsFromArray:imageIdList];
						   }
						   
						   if ([docIdList count]) {
							 [toFetchImageIdList addObjectsFromArray:docIdList];
						   }
						   
						   if ([webthumbIdList count]) {
							 [toFetchImageIdList addObjectsFromArray:webthumbIdList];
						   }
						   
						 }
						 
						 if ([toFetchImageIdList count]) {
						   
						   NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
						   context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
						   
						   for (NSString *identifier in toFetchImageIdList) {
							 
							 NSMutableDictionary *attach = [@{
															@"object_id": identifier,
															@"outdated": @YES,	// outdated, require sync from cloud
															} mutableCopy];
							 
							 // create an WAFile entry for updateAttachmentsMetaOnSuccess to batch retrieve attachment metas
							 [WAFile insertOrUpdateObjectsUsingContext:context
													withRemoteResponse:[NSArray arrayWithObject:attach]
														  usingMapping:nil
															   options:IRManagedObjectOptionIndividualOperations];
							 
						   }
						   [context save:nil];
						   
						 }
						 
						 if ([toFetchPostIdList count]) {
						   
						   IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
							 
							 [ri retrievePostsInGroup:ri.primaryGroupIdentifier withIdentifiers:toFetchPostIdList onSuccess:^(NSArray *postReps) {
							   
							   [ds performBlock:^{
								 
								 NSManagedObjectContext *context = [ds autoUpdatingMOC];
								 NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:postReps usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
								   
								 [touchedArticles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
								   
								   WAArticle *article = obj;
								   if ([ds isUpdatingArticle:[[article objectID] URIRepresentation]]) {
									 [context refreshObject:article mergeChanges:NO];
								   }
								   
								 }];
								 
								 [context save:nil];
								 
							   } waitUntilDone:YES];
							   
							   callback(nil);
							   
							 } onFailure:^(NSError *error) {
							   
							   NSLog(@"Unable to fetch posts in %@, error:%@", toFetchPostIdList, error);
							   callback(error);
							   
							 }];
							 
						   } trampoline:^(IRAsyncOperationInvoker callback) {
							 
							 NSCParameterAssert(![NSThread isMainThread]);
							 callback();
							 
						   } callback:^(id results) {
							 
							 // NO OP
							 
						   } callbackTrampoline:^(IRAsyncOperationInvoker callback) {
							   
							 NSCParameterAssert(![NSThread isMainThread]);
							 callback();
							   
						   }];

						   [wSelf.articleFetchOperationQueue addOperation:operation];

						 }
						 
						 NSOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
						   
						   NSDate *nextFetchedDate = [NSDate dateWithTimeInterval:offsetDays*24*60*60 sinceDate:currentFetchedDate];
						   [ds setEarliestDate:nextFetchedDate];
						   
						   if (!hasMore) {
							 [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAFirstArticleFetched];
							 [[NSUserDefaults standardUserDefaults] synchronize];
						   }

						   [wSelf endPostponingFetch];
						   callback(nil);
						 }];
						 
						 for (NSOperation *operation in [wSelf.articleFetchOperationQueue operations]) {
						   [tailOp addDependency:operation];
						 }
						 
						 [wSelf.articleFetchOperationQueue addOperation:tailOp];

						 callback(nil);
						 
					   } onFailure:^(NSError *error) {
						 
						 [wSelf endPostponingFetch];

						 callback(error);
						 
					   }];
	}
	
  } trampoline:^(IRAsyncOperationInvoker callback) {

	NSCParameterAssert(![NSThread isMainThread]);
	callback();
	
  } callback:^(id results) {

	// NO OP

  } callbackTrampoline:^(IRAsyncOperationInvoker callback) {

	NSCParameterAssert(![NSThread isMainThread]);
	callback();
	
  }];

  return operation;

}

- (BOOL)canPerformArticleFetch {

  if (![WARemoteInterface sharedInterface].userToken) {
    return NO;
  }

  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAFirstArticleFetched]) {
    return NO;
  }

  return YES;

}

@end
