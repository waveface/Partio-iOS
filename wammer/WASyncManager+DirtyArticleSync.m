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

@implementation WASyncManager (DirtyArticleSync)

- (IRAsyncOperation *) dirtyArticleSyncOperationPrototype {

	//	Holds NSManagedObjectIDs of Article entities being synced to their last known modification dates

	static NSMutableDictionary *idsToModDates = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    idsToModDates = [NSMutableDictionary dictionary];
	});

	__block NSManagedObjectContext *context = nil;
	
	return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
		
		WADataStore * const ds = [WADataStore defaultStore];
		context = [ds disposableMOC];
		
		[context performBlockAndWait:^{
			
			[ds enumerateDirtyArticlesInContext:context usingBlock:^(WAArticle *anArticle, NSUInteger index, BOOL *stop) {
			
				NSLog(@"Found article %@ needing sync", anArticle);
				
				//	Emit sync operation for article
				
			}];
		
		}];
		
	} trampoline:^(IRAsyncOperationInvoker block) {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
		
	} callback:^(id results) {
		
		NSLog(@"callback res %@", results);
		
	} callbackTrampoline:^(IRAsyncOperationInvoker block) {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
		
	}];

}

@end
