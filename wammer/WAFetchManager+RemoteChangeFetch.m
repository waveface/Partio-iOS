//
//  WAFetchManager+RemoteChangeFetch.m
//  wammer
//
//  Created by kchiu on 12/12/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFetchManager+RemoteChangeFetch.h"
#import "Foundation+IRAdditions.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

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
    NSDate *usedDate = [ds lastChangedPostsUpdateDate];
    if (!usedDate) {
      usedDate = wSelf.currentDate;
    }
    
    WARemoteInterface *ri = [WARemoteInterface sharedInterface];
    [ri retrieveChangesSince:usedDate inGroup:ri.primaryGroupIdentifier withEntities:NO onSuccess:^(NSArray *changedArticleIDs, NSArray *changedFileIDs, NSArray *changes, NSDate *continuation) {
      
      // no changed articles/files
      if (!continuation) {
        [ds setLastChangedPostsUpdateDate:usedDate];
        [wSelf endPostponingFetch];
        callback(nil);
        return;
      }
      
      // all articles/files changed at usedDate "should" be fully fetched, so we add one more second to avoid fetching duplicated data
      if ([usedDate isEqualToDate:continuation]) {
        [ds setLastChangedPostsUpdateDate:[usedDate dateByAddingTimeInterval:1]];
        [wSelf endPostponingFetch];
        callback(nil);
        return;
      }

      // enqueue operations to fetch changed articles from cloud
      NSMutableArray *sentChangedArticleIDs = [NSMutableArray array];
      const NSUInteger MAX_CHANGED_ARTICLES_COUNT = 100;
      [changedArticleIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        [sentChangedArticleIDs addObject:obj];
        if ([sentChangedArticleIDs count] == MAX_CHANGED_ARTICLES_COUNT || idx == [changedArticleIDs count] - 1) {
	
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
      NSMutableArray *changedFiles = [NSMutableArray array];
      for (NSString *identifier in changedFileIDs) {
        NSMutableDictionary *attach = [@{
			         @"object_id": identifier,
			         @"outdated": @YES,
			         } mutableCopy];
        
        [changedFiles addObject:attach];
      }
      [ds performBlock:^{
        
        NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
        [WAFile insertOrUpdateObjectsUsingContext:context
			 withRemoteResponse:changedFiles
			       usingMapping:nil
				  options:IRManagedObjectOptionIndividualOperations];
        [context save:nil];
        
      } waitUntilDone:YES];
      
      // add tail operation to article fetch operation queue
      NSOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
        [ds setLastChangedPostsUpdateDate:continuation];
        [wSelf endPostponingFetch];
        callback(nil);
      }];
      
      for (NSOperation *operation in [wSelf.articleFetchOperationQueue operations]) {
        [tailOp addDependency:operation];
      }
      
      [wSelf.articleFetchOperationQueue addOperation:tailOp];
      
    } onFailure:^(NSError *error) {
      
      NSLog(@"Unable to fetch remote changes since %@, error: %@", usedDate, error);
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
