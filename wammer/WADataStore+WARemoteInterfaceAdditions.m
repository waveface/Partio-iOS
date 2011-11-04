//
//  WADataStore+WARemoteInterfaceAdditions.m
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WARemoteInterface.h"

#import "WADataStore+WARemoteInterfaceAdditions.h"

@implementation WADataStore (WARemoteInterfaceAdditions)

- (void) updateUsersWithCompletion:(void(^)(void))aBlock {

	[self updateUsersOnSuccess:aBlock onFailure:aBlock];

}

- (void) updateUsersOnSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock {

	[[WARemoteInterface sharedInterface] retrieveAvailableUsersOnSuccess:^(NSArray *retrievedUserReps) {
		
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
		
		[WAUser insertOrUpdateObjectsIntoContext:context withExistingProperty:@"identifier" matchingKeyPath:@"id" ofRemoteDictionaries:retrievedUserReps];
	
		NSError *savingError = nil;
		if (![context save:&savingError])
			NSLog(@"Saving failed: %@", savingError);
		
		if (successBlock)
			successBlock();
		
	} onFailure: ^ (NSError *error) {
	
		if (failureBlock)
				failureBlock();
		
	}];

}

- (void) updateArticlesWithCompletion:(void(^)(void))aBlock {

	[self updateArticlesOnSuccess:aBlock onFailure:aBlock];

}

- (void) updateArticlesOnSuccess:(void (^)(void))successBlock onFailure:(void (^)(void))failureBlock {
	
	[[WARemoteInterface sharedInterface] retrieveArticlesWithContinuation:nil batchLimit:[WARemoteInterface sharedInterface].defaultBatchSize onSuccess:^(NSArray *retrievedArticleReps) {
	
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
		
		[WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[retrievedArticleReps irMap: ^ (NSDictionary *inUserRep, NSUInteger index, BOOL *stop) {
		
			NSMutableDictionary *mutatedRep = [[inUserRep mutableCopy] autorelease];
			
			if ([mutatedRep objectForKey:@"id"]) {
				[mutatedRep setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[inUserRep objectForKey:@"creator_id"], @"id",
				nil] forKey:@"owner"];
			}
			
			NSArray *commentReps = [mutatedRep objectForKey:@"comments"];
			if (commentReps) {
			
				[mutatedRep setObject:[commentReps irMap: ^ (NSDictionary *aCommentRep, NSUInteger index, BOOL *stop) {
				
					NSMutableDictionary *mutatedCommentRep = [[aCommentRep mutableCopy] autorelease];
					
					if ([aCommentRep objectForKey:@"creator_id"]) {
						[mutatedCommentRep setObject:[NSDictionary dictionaryWithObjectsAndKeys:
							[aCommentRep objectForKey:@"creator_id"], @"id",
						nil] forKey:@"owner"];
					}
					
					return mutatedCommentRep;
					
				}] forKey:@"comments"];
			
			}
		
			return mutatedRep;
			
		}] usingMapping:[NSDictionary dictionaryWithObjectsAndKeys:
		
			@"WAFile", @"files",
			@"WAComment", @"comments",
			@"WAUser", @"owner",
			@"WAPreview", @"previews",
		
		nil] options:IRManagedObjectOptionIndividualOperations];
		
		NSError *savingError = nil;
		if (![context save:&savingError])
			NSLog(@"Saving Error %@", savingError);
		
		if (successBlock)
			successBlock();
		
	} onFailure: ^ (NSError *error) {
		
		if (failureBlock)
			failureBlock();
		
	}];

}

- (void) uploadArticle:(NSURL *)anArticleURI withCompletion:(void(^)(void))aBlock {

	[self uploadArticle:anArticleURI onSuccess:aBlock onFailure:aBlock];

}

- (void) uploadArticle:(NSURL *)anArticleURI onSuccess:(void (^)(void))successBlock onFailure:(void (^)(void))failureBlock {

	NSParameterAssert(anArticleURI);

	NSString *currentUserIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:kWALastAuthenticatedUserIdentifier];
	
	NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
	WAArticle *updatedArticle = (WAArticle *)[context irManagedObjectForURI:anArticleURI];
			
	void (^uploadArticleIfAppropriate)(NSURL *articleURL) = ^ (NSURL *articleURL) {
	
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		WAArticle *updatedArticle = (WAArticle *)[context irManagedObjectForURI:articleURL];
		
		NSMutableArray *remoteFileIdentifiers = [NSMutableArray array];
		
		for (NSURL *aFileObjectURI in updatedArticle.fileOrder) {
			WAFile *aFile = (WAFile *)[context irManagedObjectForURI:aFileObjectURI];
			if (!aFile.identifier) {
				NSLog(@"Article file %@ does not have a remote identifier; bailing upload pending future invocation.", aFile);
				return;
			}
			[remoteFileIdentifiers addObject:aFile.identifier];
		}
		
		[[WARemoteInterface sharedInterface] createArticleAsUser:currentUserIdentifier withText:updatedArticle.text attachments:remoteFileIdentifiers usingDevice:[UIDevice currentDevice].model onSuccess:^(NSDictionary *createdCommentRep) {
		
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObject:createdCommentRep] usingMapping:[NSDictionary dictionaryWithObjectsAndKeys:
	
				@"WAFile", @"files",
				@"WAComment", @"comments",
				@"WAUser", @"owner",
				@"WAPreview", @"previews",
			
			nil] options:IRManagedObjectOptionIndividualOperations];
			
			for (WAArticle *anArticle in touchedArticles) {
				anArticle.draft = (NSNumber *)kCFBooleanFalse;
				NSLog(@"article %@, previews %@", anArticle, anArticle.previews);
			}
			
			if (successBlock)
				successBlock();
			
		} onFailure:^(NSError *error) {
		
			NSLog(@"Fail %@", error);
			
			if (failureBlock)
				failureBlock();
			
		}];

	};
	
	if (![updatedArticle.fileOrder count]) {
	
		//	If there are no attachments, all the merry
		//	Just send the article out and call it done.
		
		uploadArticleIfAppropriate(anArticleURI);
		return;
		
	}
	
	
	//	Otherwise, work up a queue.
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_group_t group = dispatch_group_create();
	
	for (NSURL *aFileObjectURI in updatedArticle.fileOrder) {
	
		dispatch_group_async(group, queue, ^ {
		
			__block NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			__block WAFile *updatedFile = (WAFile *)[context irManagedObjectForURI:aFileObjectURI];
			
			dispatch_queue_t currentQueue = dispatch_get_current_queue();
			dispatch_retain(currentQueue);
			
			[[WARemoteInterface sharedInterface] uploadFileAtURL:[NSURL fileURLWithPath:updatedFile.resourceFilePath] asUser:currentUserIdentifier onSuccess:^(NSDictionary *uploadedFileRep) {
			
				//	Guarding against accidental crossing of thread boundaries
				context = (id)0x1;
				updatedFile = (id)0x1;
			
				NSManagedObjectContext *refreshingContext = [[WADataStore defaultStore] disposableMOC];
				refreshingContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
				
				WAFile *refreshedFile = (WAFile *)[refreshingContext irManagedObjectForURI:aFileObjectURI];
				[refreshedFile configureWithRemoteDictionary:uploadedFileRep];
				
				NSError *savingError = nil;
				if (![refreshingContext save:&savingError])
					NSLog(@"Error saving: %@", savingError);
				
				NSURL *articleURL = [[refreshedFile.article objectID] URIRepresentation];
				
				dispatch_async(currentQueue, ^ {
					uploadArticleIfAppropriate(articleURL);
				});
				
				dispatch_release(currentQueue);
				
			} onFailure:^(NSError *error) {
			
				//	Guarding against accidental crossing of thread boundaries
				context = (id)0x1;
				updatedFile = (id)0x1;
				
				//	if (failureBlock)
				//		failureBlock();
				
				NSLog(@"Failed uploading file: %@", error);
				NSLog(@"TBD: handle this gracefully");
				
			}];

		});
	
	}
	
	dispatch_release(group);

}

@end
