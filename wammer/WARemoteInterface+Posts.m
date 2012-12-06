//
//  WARemoteInterface+Posts.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Posts.h"
#import "WADataStore.h"

@implementation WARemoteInterface (Posts)

+ (NSDictionary *) postEntityWithGroupID:(NSString *)groupID postID:(NSString *)postID text:(NSString *)text attachments:(NSArray *)attachmentIDs mainAttachment:(NSString *)mainAttachmentID preview:(NSDictionary *)previewRep isFavorite:(BOOL)isFavorite isHidden:(BOOL)isHidden isImport:(BOOL)isImport createTime:(NSDate *)createTime updateTime:(NSDate *)updateTime {

	NSMutableDictionary *sentData = [NSMutableDictionary dictionary];

	sentData[@"type"] = @"text";

	if (groupID)
		sentData[@"group_id"] = groupID;
	
	if (postID)
		sentData[@"post_id"] = postID;	
	
	if (text)
		sentData[@"content"] = IRWebAPIKitStringValue(text);
	
	if ([attachmentIDs count]) {
		sentData[@"attachment_id_array"] = [attachmentIDs JSONString];
		sentData[@"type"] = @"image";
	}
	
	if (mainAttachmentID)
		sentData[@"cover_attach"] = mainAttachmentID;
	
	if (previewRep) {
		sentData[@"preview"] = [previewRep JSONString];
		sentData[@"type"] = @"link";
	}
	
	//	This is fubar, we should NOT use 1 to 5 for fave and string literals for hidden status
	
	sentData[@"hidden"] = (isHidden ? @"true" : @"false");
	sentData[@"favorite"] = (isFavorite ? @"1" : @"0");
	if (isImport) {
		sentData[@"import"] = @"true";
	}
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
	formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

	if (createTime) {

		sentData[@"timestamp"] = [formatter stringFromDate:createTime];

	}
	
	if (updateTime) {

		sentData[@"update_time"] = [formatter stringFromDate:updateTime];

	}

	return sentData;

}

- (void) retrievePost:(NSString *)anIdentifier inGroup:(NSString *)aGroupIdentifier onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(anIdentifier);
	NSParameterAssert(aGroupIdentifier);
	
	[self.engine fireAPIRequestNamed:@"posts/getSingle" withArguments:@{@"group_id": aGroupIdentifier,
		@"post_id": anIdentifier} options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"post"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
	
}

- (void) retrievePostsInGroup:(NSString *)aGroupIdentifier relativeToPost:(NSString *)referencedPostOrNil date:(NSDate *)referencedDateOrNil withSearchLimits:(NSInteger)positiveOrNegativeNumberOfPostsToExpandSearching filter:(id)aFilterPlaceholder onSuccess:(void (^)(NSArray *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	//	Assert post XOR date.
	NSParameterAssert((!referencedPostOrNil ^ !referencedDateOrNil));
	NSParameterAssert(aGroupIdentifier);
	
	NSString *datum = referencedPostOrNil;
	if (!datum) {
	
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		datum = [formatter stringFromDate:referencedDateOrNil];
	
	}
	
	[self.engine fireAPIRequestNamed:@"posts/get" withArguments:@{@"group_id": aGroupIdentifier,
		@"datum": datum,
    
                @"limit": [NSString stringWithFormat:@"%@%ld",
                  (positiveOrNegativeNumberOfPostsToExpandSearching > 0) ? @"+" : @"",
                  (long)positiveOrNegativeNumberOfPostsToExpandSearching
                ],
                
		@"filter": @""} options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"posts"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveLatestPostsInGroup:(NSString *)aGroupIdentifier withBatchLimit:(NSUInteger)maxNumberOfReturnedPosts onSuccess:(void (^)(NSArray *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(aGroupIdentifier);
	
	[self.engine fireAPIRequestNamed:@"posts/getLatest" withArguments:@{@"group_id": aGroupIdentifier,
		@"limit": @(maxNumberOfReturnedPosts)} options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"posts"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) createPostInGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil attachments:(NSArray *)attachmentIdentifiersOrNil preview:(NSDictionary *)aPreviewRep postId:(NSString *)postID createTime:(NSDate *)createTime updateTime:(NSDate *)updateTime favorite:(BOOL)isFavorite import:(BOOL)isImport onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(aGroupIdentifier);
	
	NSDictionary *postEntity = [[self class] postEntityWithGroupID:aGroupIdentifier postID:postID text:contentTextOrNil attachments:attachmentIdentifiersOrNil mainAttachment:nil preview:aPreviewRep isFavorite:isFavorite isHidden:NO isImport:isImport createTime:createTime updateTime:updateTime];

	[self.engine fireAPIRequestNamed:@"posts/new" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(postEntity, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (!successBlock)
			return;
		
		successBlock(
			[inResponseOrNil valueForKey:@"post"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) updatePost:(NSString *)postID inGroup:(NSString *)groupID withText:(NSString *)text attachments:(NSArray *)attachmentIDs mainAttachment:(NSString *)mainAttachmentID preview:(NSDictionary *)preview favorite:(BOOL)isFavorite hidden:(BOOL)isHidden replacingDataWithDate:(NSDate *)lastKnownModificationDate updateTime:(NSDate *)updateTime onSuccess:(void(^)(NSDictionary *postRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSMutableDictionary *postEntity = [[[self class] postEntityWithGroupID:groupID postID:postID text:text attachments:attachmentIDs mainAttachment:mainAttachmentID preview:preview isFavorite:isFavorite isHidden:isHidden isImport:NO createTime:nil updateTime:updateTime] mutableCopy];
	
	if (lastKnownModificationDate) {
	
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

		NSString *lastKnownModificationDateString = [formatter stringFromDate:lastKnownModificationDate];
		postEntity[@"last_update_time"] = lastKnownModificationDateString;
	
	}
	
	[self.engine fireAPIRequestNamed:@"posts/update" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(postEntity, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (!successBlock)
			return;
		
		successBlock(
			[inResponseOrNil valueForKey:@"post"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) createCommentForPost:(NSString *)aPostIdentifier inGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	[self.engine fireAPIRequestNamed:@"posts/newComment" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(@{@"group_id": aGroupIdentifier,
		@"post_id": aPostIdentifier,
		@"content": contentTextOrNil}, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (!successBlock)
			return;
		
		successBlock(inResponseOrNil[@"post"]);

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrievePostsInGroup:(NSString *)aGroupIdentifier
									usingFilter:(id)aFilter
										onSuccess:(void(^)(NSArray *postReps))successBlock
										onFailure:(void(^)(NSError *error))failureBlock {

  NSParameterAssert(aGroupIdentifier);
  NSParameterAssert(aFilter);
  
  NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    aGroupIdentifier, @"group_id",
  nil];

  if ([aFilter isKindOfClass:[NSString class]]) {
    arguments[@"filter_id"] = aFilter;
  } else if ([aFilter isKindOfClass:[NSDictionary class]]) {
    arguments[@"filter_entity"] = [(NSDictionary *)aFilter JSONString];
  }

  arguments[@"component_options"] = [@[@"content"] JSONString];

  [self.engine
	 fireAPIRequestNamed:@"posts/fetchByFilter"
	 withArguments:arguments
	 options:nil
	 validator:WARemoteInterfaceGenericNoErrorValidator()
	 successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		 
		 if (!successBlock)
			 return;
		 
		 successBlock(inResponseOrNil[@"posts"]);
		 
	 }
	 failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)
	 ];

}

- (void) retrievePostsInGroup:(NSString *)groupID
							withIdentifiers:(NSArray *)postIDs
										onSuccess:(void(^)(NSArray *postReps))successBlock
										onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(groupID);
	NSParameterAssert(postIDs);
	
	NSMutableDictionary *postListEntity = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																				 groupID, @"group_id",
																				 [postIDs JSONString], @"post_id_list",
																				 [@[@"comment", @"preview", @"soul", @"content"] JSONString], @"component_options",
																				 nil];
	
	[self.engine
	 fireAPIRequestNamed:@"posts/fetchByFilter"
	 withArguments:nil
	 options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(postListEntity, nil)
	 validator:WARemoteInterfaceGenericNoErrorValidator()
	 successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		 
		 if (!successBlock)
			 return;
		 
		 successBlock(inResponseOrNil[@"posts"]);
		 
	 }
	 failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) createSharableSnapshotForPost:(NSString *)aPostIdentifier inGroup:(NSString *)aGroupIdentifier onSuccess:(void (^)(NSString *))successBlock onFailure:(void (^)(NSError *))failureBlock {

  NSParameterAssert(aPostIdentifier);
  NSParameterAssert(aGroupIdentifier);

	[self.engine fireAPIRequestNamed:@"posts/takeSnapshot" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(@{@"group_id": aGroupIdentifier,
		@"post_id": aPostIdentifier}, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (!successBlock)
			return;
		
		successBlock(inResponseOrNil[@"access_token"]);

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveSharableSnapshotForPost:(NSString *)aPostIdentifier usingToken:(NSString *)aToken onSuccess:(void(^)(NSDictionary *aPostRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

  NSParameterAssert(aPostIdentifier);
  NSParameterAssert(aToken);
  
  [self.engine fireAPIRequestNamed:@"posts/getSnapshot" withArguments:@{@"post_id": aPostIdentifier,
    @"access_token": aToken} options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
  
    if (!successBlock)
      return;
    
    successBlock(inResponseOrNil[@"post"]);
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) configurePost:(NSString *)postID inGroup:(NSString *)groupID withVisibilityStatus:(BOOL)willBeVisible onSuccess:(void (^)(void))aSuccessBlock onFailure:(void (^)(NSError *))failureBlock {

  NSString *methodName = willBeVisible ? @"posts/unhide" : @"posts/hide";

	[self.engine fireAPIRequestNamed:methodName withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(@{@"post_id": postID,
		@"group_id": groupID}, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (aSuccessBlock)
      aSuccessBlock();

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
