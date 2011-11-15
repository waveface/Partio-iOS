//
//  WARemoteInterface+Posts.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Posts)

//	GET posts/getSingle
- (void) retrievePost:(NSString *)anIdentifier inGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(NSDictionary *postRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	GET posts/get
- (void) retrievePostsInGroup:(NSString *)aGroupIdentifier relativeToPost:(NSString *)referencedPostOrNil date:(NSDate *)referencedDateOrNil withSearchLimits:(NSInteger)positiveOrNegativeNumberOfPostsToExpandSearching filter:(id)aFilterPlaceholder onSuccess:(void(^)(NSArray *postReps))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	GET posts/getLatest
- (void) retrieveLatestPostsInGroup:(NSString *)aGroupIdentifier withBatchLimit:(NSUInteger)maxNumberOfReturnedPosts onSuccess:(void(^)(NSArray *postReps))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST posts/new
- (void) createPostInGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil attachments:(NSArray *)attachmentIdentifiersOrNil preview:(NSDictionary *)aPreviewRep onSuccess:(void(^)(NSDictionary *postRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST posts/newComment
- (void) createCommentForPost:(NSString *)aPostIdentifier inGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil onSuccess:(void(^)(NSDictionary *updatedPostRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;;

@end