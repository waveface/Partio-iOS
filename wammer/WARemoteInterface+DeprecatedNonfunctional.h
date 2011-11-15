//
//  WARemoteInterface+DeprecatedNonfunctional.h
//  wammer
//
//  Created by Evadne Wu on 11/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Deprecated_Nonfunctional)

- (IRWebAPIRequestContextTransformer) defaultV1AuthenticationSignatureBlock DEPRECATED_ATTRIBUTE;
- (IRWebAPIRequestContextTransformer) defaultV1QueryHack DEPRECATED_ATTRIBUTE;

- (void) retrieveAvailableUsersOnSuccess:(void(^)(NSArray *retrievedUserReps))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

- (void) retrieveArticlesWithContinuation:(id)aContinuation batchLimit:(NSUInteger)maximumNumberOfArticles onSuccess:(void(^)(NSArray *retrievedArticleReps))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

- (void) retrieveArticleWithRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *retrievedArticleRep))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

- (void) retrieveCommentsOfArticleWithRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSArray *retrievedComentReps))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

- (void) createArticleAsUser:(NSString *)creatorIdentifier withText:(NSString *)bodyText attachments:(NSArray *)attachmentIdentifiers usingDevice:(NSString *)creationDeviceName onSuccess:(void(^)(NSDictionary *createdCommentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

- (void) uploadFileAtURL:(NSURL *)aFileURL asUser:(NSString *)creatorIdentifier onSuccess:(void(^)(NSDictionary *uploadedFileRep))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

- (void) createCommentAsUser:(NSString *)creatorIdentifier forArticle:(NSString *)anIdentifier withText:(NSString *)bodyText usingDevice:(NSString *)creationDeviceName onSuccess:(void(^)(NSDictionary *createdCommentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

- (void) retrieveLastReadArticleRemoteIdentifierOnSuccess:(void(^)(NSString *lastID, NSDate *modDate))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

- (void) setLastReadArticleRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *response))successBlock onFailure:(void(^)(NSError *error))failureBlock DEPRECATED_ATTRIBUTE;

@end
