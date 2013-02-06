//
//  WAFetchManager+RemoteChangeFetch.m
//  wammer
//
//  Created by kchiu on 12/12/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFetchManager+RemoteChangeFetch.h"
#import "WADefines.h"
#import "Foundation+IRAdditions.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WACollection+RemoteOperations.h"

@implementation WAFetchManager (RemoteChangeFetch)

- (IRAsyncOperation *)remoteChangeFetchOperationPrototype {
	
	__weak WAFetchManager *wSelf = self;
	
	IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
		
		if (![wSelf canPerformChangeFetch]) {
			callback(nil);
			return;
		}
		
		[wSelf beginPostponingFetch];
		
		WADataStore *ds = [WADataStore defaultStore];
		NSNumber *currentSeq = [ds maxSequenceNumber];
		
		WARemoteInterface *ri = [WARemoteInterface sharedInterface];
		
		[ri retrieveChangesSince:currentSeq inGroup:ri.primaryGroupIdentifier onSuccess:^(NSArray *changedArticles, NSArray *changedFiles, NSArray *changedCollections, NSNumber *nextSeq) {
			
			// Nothing changed
			if (![changedArticles count] && ![changedFiles count] && ![changedCollections count]) {
				[wSelf endPostponingFetch];
				callback(nil);
				return;
			}
			
			if ([changedCollections count]) {
				[WACollection fetchByIdentifiers:changedCollections];
			}
			
			// enqueue operations to fetch changed articles from cloud
			NSMutableArray *sentChangedArticleIDs = [NSMutableArray array];
			const NSUInteger MAX_CHANGED_ARTICLES_COUNT = 100;
			[changedArticles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				
				[sentChangedArticleIDs addObject:obj[@"post_id"]];
				if ([sentChangedArticleIDs count] == MAX_CHANGED_ARTICLES_COUNT || idx == [changedArticles count] - 1) {
					
					NSArray *sentChangedArticleIDsCopy = [NSArray arrayWithArray:sentChangedArticleIDs];
					IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
						
						[ri retrievePostsInGroup:ri.primaryGroupIdentifier withIdentifiers:sentChangedArticleIDsCopy onSuccess:^(NSArray *postReps) {
							
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
							
							NSLog(@"Unable to fetch posts in %@, error:%@", sentChangedArticleIDs, error);
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
					
					[sentChangedArticleIDs removeAllObjects];
					
				}
				
			}];
			
			// mark changed attachments as outdated, require fetch from cloud
			NSMutableArray *outdatedFiles = [NSMutableArray array];
			for (NSDictionary *file in changedFiles) {
				NSMutableDictionary *attach = [@{
																			 @"object_id": file[@"attachment_id"],
																			 @"outdated": @YES,
																			 } mutableCopy];
				
				[outdatedFiles addObject:attach];
			}
			
			[ds performBlock:^{
				
				NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
				[WAFile insertOrUpdateObjectsUsingContext:context
															 withRemoteResponse:outdatedFiles
																		 usingMapping:nil
																					options:IRManagedObjectOptionIndividualOperations];
				[context save:nil];
				
			} waitUntilDone:YES];
			
			// add tail operation to article fetch operation queue
			IRAsyncBarrierOperation *tailOp = [IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
				[ds setMaxSequenceNumber:nextSeq];
				callback(nil);
			} trampoline:^(IRAsyncOperationInvoker callback) {
				NSCParameterAssert(![NSThread isMainThread]);
				callback();
			} callback:^(id results) {
				// -[WASyncManager endPostponingSync] must be called no matter the operations are succeed or not
				[wSelf endPostponingFetch];
				callback(results);
			} callbackTrampoline:^(IRAsyncOperationInvoker callback) {
				NSCParameterAssert(![NSThread isMainThread]);
				callback();
			}];
			
			for (IRAsyncOperation *operation in [wSelf.articleFetchOperationQueue operations]) {
				[tailOp addDependency:operation];
			}
			
			[wSelf.articleFetchOperationQueue addOperation:tailOp];
			
		} onFailure:^(NSError *error) {
			
			if (error.code == (0xB000 + 5)) {
				
				// No OP for USERTRACK.NO_USERTRACKS_TO_HANDLE
				
			} else if (error.code == (0xB000 + 4) || error.code == (0xB000 + 7)) {
				
				// Refetch all posts for USERTRACK.TOO_OLD_SEQ_NUM & USERTRACK.TOO_MANY_TO_HANDLE
				NSLog(@"Reset the min seq number and re-fetch all posts: %@", error);
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAFirstArticleFetched];
				[ds setMinSequenceNumber:@(INT_MAX)]; // restart fetching the articles from current sequential number
			  [ds setEarliestDate:[NSDate date]];
				
			} else {
				
				NSLog(@"Unable to fetch remote changes since %@, error: %@", currentSeq, error);
				
			}
			
			[wSelf endPostponingFetch];
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
	
	return operation;
	
}

- (BOOL)canPerformChangeFetch {
	
	if (![WARemoteInterface sharedInterface].userToken) {
		return NO;
	}
	
	return YES;
	
}

@end
