//
//  WASyncManager+DirtyArticleSync.m
//  wammer
//
//  Created by Evadne Wu on 6/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASyncManager+DirtyArticleSync.h"
#import "Foundation+IRAdditions.h"
#import "IRRecurrenceMachine.h"
#import "WADataStore+WASyncManagerAdditions.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WARemoteInterface.h"
#import "WADefines+iOS.h"
#import "WAAppDelegate_iOS.h"
#import "WADefines.h"

@implementation WASyncManager (DirtyArticleSync)

- (IRAsyncOperation *) dirtyArticleSyncOperationPrototype {
  
  __weak WASyncManager *wSelf = self;
  
  return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

    if (![wSelf canPerformArticleSync]) {
      callback(nil);
      return;
    }

    WADataStore *ds = [WADataStore defaultStore];
    NSMutableArray *articleURIs = [NSMutableArray array];

    __block NSUInteger filesCount = 0;
    [ds enumerateDirtyArticlesInContext:nil usingBlock:^(WAArticle *anArticle, NSUInteger index, BOOL *stop) {
      
      filesCount += [anArticle.files count];
      NSURL *articleURL = [[anArticle objectID] URIRepresentation];
      [articleURIs addObject:articleURL];
      
    }];
    
    if ([articleURIs count] == 0) {
      callback(nil);
      return;
    }

    NSAssert(wSelf.needingSyncFilesCount == 0, @"file sync count should be reset before starting article sync");
    wSelf.needingSyncFilesCount = filesCount; // display status bar via KVO

    [[wSelf recurrenceMachine] beginPostponingOperations];

    for (NSURL *articleURL in articleURIs) {

      // manual updated articles are possibly already in the updating article list
      if (![ds isUpdatingArticle:articleURL]) {

        IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

	[ds updateArticle:articleURL onSuccess:^{
	  callback(nil);
	} onFailure:^(NSError *error) {
	  callback(error);
	}];

        } trampoline:^(IRAsyncOperationInvoker callback) {

	NSParameterAssert(![NSThread isMainThread]);
	callback();

        } callback:^(id results) {

	// NO OP

        } callbackTrampoline:^(IRAsyncOperationInvoker callback) {

	NSParameterAssert(![NSThread isMainThread]);
	callback();

        }];
        
        [wSelf.articleSyncOperationQueue addOperation:operation];

      }

    }
    
    NSBlockOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
      [[wSelf recurrenceMachine] endPostponingOperations];
    }];
    
    for (NSOperation *operation in wSelf.articleSyncOperationQueue.operations) {
      [tailOp addDependency:operation];
    }
    
    [wSelf.articleSyncOperationQueue addOperation:tailOp];

    callback((id)kCFBooleanTrue);
    
  } trampoline:^(IRAsyncOperationInvoker block) {
    
    NSParameterAssert(![NSThread isMainThread]);
    block();
    
  } callback:^(id results) {
    
    // NO OP
    
  } callbackTrampoline:^(IRAsyncOperationInvoker block) {
    
    NSParameterAssert(![NSThread isMainThread]);
    block();
    
  }];
  
}

- (BOOL)canPerformArticleSync {

  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    return NO;
  }
  
  WAPhotoImportManager *photoImportManager = [(WAAppDelegate_iOS *)AppDelegate() photoImportManager];
  if (photoImportManager.preprocessing || photoImportManager.operationQueue.operationCount > 0) {
    return NO;
  }
  
  WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
  if (!ri.userToken) {
    return NO;
  }

  return YES;

}

@end
