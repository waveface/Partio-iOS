//
//  WADataStore+WARemoteInterfaceAdditions.h
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADataStore.h"

@interface WADataStore (WARemoteInterfaceAdditions)

- (void) updateUsersOnSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock DEPRECATED_ATTRIBUTE;
- (void) updateArticlesOnSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock DEPRECATED_ATTRIBUTE;

- (void) uploadArticle:(NSURL *)anArticleURI onSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock DEPRECATED_ATTRIBUTE;

- (void) updateUsersWithCompletion:(void(^)(void))aBlock DEPRECATED_ATTRIBUTE;
- (void) updateArticlesWithCompletion:(void(^)(void))aBlock DEPRECATED_ATTRIBUTE;
- (void) uploadArticle:(NSURL *)anArticleURI withCompletion:(void(^)(void))aBlock DEPRECATED_ATTRIBUTE;

@end
