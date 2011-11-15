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

- (void) updateArticlesWithCompletion:(void(^)(void))aBlock {

	[self updateArticlesOnSuccess:aBlock onFailure:aBlock];

}

- (void) updateArticlesOnSuccess:(void (^)(void))successBlock onFailure:(void (^)(void))failureBlock {

	[WAArticle synchronizeWithCompletion:^(BOOL didFinish, NSManagedObjectContext *temporalContext, NSArray *prospectiveUnsavedObjects, NSError *anError) {
	
		if (!didFinish) {
			if (failureBlock)
				failureBlock();
			return;
		}
		
		if (![temporalContext save:nil]) {
			if (failureBlock)
				failureBlock();
			return;
		}
		
		if (successBlock)
			successBlock();
		
	}];
	
}

- (void) uploadArticle:(NSURL *)anArticleURI withCompletion:(void(^)(void))aBlock {

	[self uploadArticle:anArticleURI onSuccess:aBlock onFailure:aBlock];

}

- (void) uploadArticle:(NSURL *)anArticleURI onSuccess:(void (^)(void))successBlock onFailure:(void (^)(void))failureBlock {

	__block NSManagedObjectContext *context = [[self disposableMOC] retain];
	__block WAArticle *updatedArticle = (WAArticle *)[context irManagedObjectForURI:anArticleURI];
	
	void (^cleanup)() = ^ {
		[context autorelease];
	};
	
	[updatedArticle synchronizeWithCompletion:^(BOOL didFinish, NSManagedObjectContext *temporalContext, NSManagedObject *prospectiveUnsavedObject, NSError *anError) {
	
		if (!didFinish) {
			
			if (failureBlock)
				failureBlock();
			
			cleanup();
			return;
			
		}
		
		if (![temporalContext save:nil]) {
			
			if (failureBlock)
				failureBlock();
			
			cleanup();
			return;
			
		}
		
		if (successBlock)
			successBlock();
		
		cleanup();
		
	}];
	
}

@end
