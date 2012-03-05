//
//  WADataStore+WARemoteInterfaceAdditions.h
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADataStore.h"
#import "WARemoteInterfaceEntitySyncing.h"
#import "WAArticle+WARemoteInterfaceEntitySyncing.h"
#import "WAFile+WARemoteInterfaceEntitySyncing.h"


@interface WADataStore (WARemoteInterfaceAdditions)

- (BOOL) hasDraftArticles;
- (void) updateArticlesOnSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *))failureBlock;
- (void) uploadArticle:(NSURL *)anArticleURI onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

- (BOOL) isUploadingArticle:(NSURL *)anObjectURI;	//	Really?

- (void) addComment:(NSString *)commentText onArticle:(NSURL *)anArticleURI onSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock;

- (void) updateCurrentUserOnSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock;

@end
