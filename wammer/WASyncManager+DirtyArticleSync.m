//
//  WASyncManager+DirtyArticleSync.m
//  wammer
//
//  Created by Evadne Wu on 6/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASyncManager+DirtyArticleSync.h"
#import "Foundation+IRAdditions.h"
#import "WADataStore+WASyncManagerAdditions.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WARemoteInterface.h"
#import "WADefines+iOS.h"
#import "WAAppDelegate_iOS.h"

@implementation WASyncManager (DirtyArticleSync)

- (IRAsyncOperation *) dirtyArticleSyncOperationPrototype {

	__block NSManagedObjectContext *context = nil;
	
	return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
		
		if ([(WAAppDelegate_iOS *)AppDelegate() photoImportManager].operationQueue.operationCount > 0) {
			callback(nil);
			return;
		}

		WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
		if (!ri.userToken) {
			callback(nil);
			return;
		}
		
		WADataStore * const ds = [WADataStore defaultStore];
		context = [ds disposableMOC];
		
		[context performBlockAndWait:^{
		
			NSMutableArray *articleURIs = [NSMutableArray array];
			
			[ds enumerateDirtyArticlesInContext:context usingBlock:^(WAArticle *anArticle, NSUInteger index, BOOL *stop) {
			
				NSURL *articleURL = [[anArticle objectID] URIRepresentation];
				[articleURIs addObject:articleURL];
				
			}];

			dispatch_async(dispatch_get_main_queue(), ^{
			
				for (NSURL *articleURL in articleURIs)
					if (![ds isUpdatingArticle:articleURL])
						[ds updateArticle:articleURL onSuccess:nil onFailure:nil];
				
				callback((id)kCFBooleanTrue);
				
			});

		}];
		
	} trampoline:^(IRAsyncOperationInvoker block) {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
		
	} callback:^(id results) {
		
		//	NO OP
		
	} callbackTrampoline:^(IRAsyncOperationInvoker block) {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
		
	}];

}

@end
