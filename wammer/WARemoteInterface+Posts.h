//
//  WARemoteInterface+Posts.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Posts)

+ (NSDictionary *) postEntityWithGroupID:(NSString *)groupID postID:(NSString *)postID text:(NSString *)text attachments:(NSArray *)attachmentIDs mainAttachment:(NSString *)mainAttachmentID preview:(NSDictionary *)previewRep isFavorite:(BOOL)isFavorite;

//	GET posts/getSingle
- (void) retrievePost:(NSString *)anIdentifier inGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(NSDictionary *postRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	GET posts/get
- (void) retrievePostsInGroup:(NSString *)aGroupIdentifier relativeToPost:(NSString *)referencedPostOrNil date:(NSDate *)referencedDateOrNil withSearchLimits:(NSInteger)positiveOrNegativeNumberOfPostsToExpandSearching filter:(id)aFilterPlaceholder onSuccess:(void(^)(NSArray *postReps))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	GET posts/getLatest
- (void) retrieveLatestPostsInGroup:(NSString *)aGroupIdentifier withBatchLimit:(NSUInteger)maxNumberOfReturnedPosts onSuccess:(void(^)(NSArray *postReps))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST posts/new
- (void) createPostInGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil attachments:(NSArray *)attachmentIdentifiersOrNil preview:(NSDictionary *)aPreviewRep onSuccess:(void(^)(NSDictionary *postRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST posts/update
- (void) updatePost:(NSString *)postID inGroup:(NSString *)groupID withText:(NSString *)text attachments:(NSArray *)attachmentIDs mainAttachment:(NSString *)mainAttachmentID preview:(NSDictionary *)preview favorite:(BOOL)isFavorite replacingDataWithDate:(NSDate *)lastKnownModificationDate onSuccess:(void(^)(NSDictionary *postRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST posts/newComment
- (void) createCommentForPost:(NSString *)aPostIdentifier inGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil onSuccess:(void(^)(NSDictionary *updatedPostRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//  GET posts/fetchByFilter
- (void) retrievePostsInGroup:(NSString *)aGroupIdentifier usingFilter:(id)aFilter onSuccess:(void(^)(NSArray *postReps))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//  POST posts/takeSnapshot
- (void) createSharableSnapshotForPost:(NSString *)aPostIdentifier inGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(NSString *snapshotAccessToken))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//  GET posts/getSnapshot — No authentication required
- (void) retrieveSharableSnapshotForPost:(NSString *)aPostIdentifier usingToken:(NSString *)aToken onSuccess:(void(^)(NSDictionary *aPostRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//  POST posts/hide
//  POST posts/unhide
- (void) configurePost:(NSString *)aPostIdentifier withVisibilityStatus:(BOOL)willBeVisible onSuccess:(void(^)(void))aSuccessBlock onFailure:(void(^)(NSError *error))failureBlock;

@end