//
//  WARemoteInterface+Posts.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Posts.h"

@implementation WARemoteInterface (Posts)

+ (NSDictionary *) postEntityWithGroupID:(NSString *)groupID postID:(NSString *)postID text:(NSString *)text attachments:(NSArray *)attachmentIDs mainAttachment:(NSString *)mainAttachmentID preview:(NSDictionary *)previewRep isFavorite:(BOOL)isFavorite {

	NSMutableDictionary *sentData = [NSMutableDictionary dictionary];

	[sentData setObject:@"text" forKey:@"type"];

	if (groupID)
		[sentData setObject:groupID forKey:@"group_id"];
	
	if (postID)
		[sentData setObject:postID forKey:@"post_id"];
	
	if (text)
		[sentData setObject:IRWebAPIKitStringValue(text) forKey:@"content"];
	
	if ([attachmentIDs count]) {
		[sentData setObject:[attachmentIDs JSONString] forKey:@"attachment_id_array"];
		[sentData setObject:@"image" forKey:@"type"];
	}
	
	if (mainAttachmentID)
		[sentData setObject:mainAttachmentID forKey:@"cover_attach"];
	
	if (previewRep) {
		[sentData setObject:[previewRep JSONString] forKey:@"preview"];
		[sentData setObject:@"link" forKey:@"type"];
	}
	
	[sentData setObject:(isFavorite ? @"1" : @"0") forKey:@"favorite"];	//	This is fubar, we should NOT use 1 to 5
	
	return sentData;

}

- (void) retrievePost:(NSString *)anIdentifier inGroup:(NSString *)aGroupIdentifier onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(anIdentifier);
	NSParameterAssert(aGroupIdentifier);
	
	[self.engine fireAPIRequestNamed:@"posts/getSingle" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
		
		aGroupIdentifier, @"group_id",
		anIdentifier, @"post_id",
				
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
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
	
	[self.engine fireAPIRequestNamed:@"posts/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
		
		aGroupIdentifier, @"group_id",
		datum, @"datum",
    
                [NSString stringWithFormat:@"%@%i", 
                  (positiveOrNegativeNumberOfPostsToExpandSearching > 0) ? @"+" : @"",
                  positiveOrNegativeNumberOfPostsToExpandSearching
                ], @"limit",
                
		@"", @"filter",
				
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"posts"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveLatestPostsInGroup:(NSString *)aGroupIdentifier withBatchLimit:(NSUInteger)maxNumberOfReturnedPosts onSuccess:(void (^)(NSArray *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(aGroupIdentifier);
	
	[self.engine fireAPIRequestNamed:@"posts/getLatest" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		[NSNumber numberWithUnsignedInt:maxNumberOfReturnedPosts], @"limit",
	
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"posts"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) createPostInGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil attachments:(NSArray *)attachmentIdentifiersOrNil preview:(NSDictionary *)aPreviewRep onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(aGroupIdentifier);
	
	NSDictionary *postEntity = [[self class] postEntityWithGroupID:aGroupIdentifier postID:nil text:contentTextOrNil attachments:attachmentIdentifiersOrNil mainAttachment:nil preview:aPreviewRep isFavorite:NO];

	[self.engine fireAPIRequestNamed:@"posts/new" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(postEntity, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (!successBlock)
			return;
		
		successBlock(
			[inResponseOrNil valueForKey:@"post"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) updatePost:(NSString *)postID inGroup:(NSString *)groupID withText:(NSString *)text attachments:(NSArray *)attachmentIDs mainAttachment:(NSString *)mainAttachmentID preview:(NSDictionary *)preview favorite:(BOOL)isFavorite replacingDataWithDate:(NSDate *)lastKnownModificationDate onSuccess:(void(^)(NSDictionary *postRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSMutableDictionary *postEntity = [[[self class] postEntityWithGroupID:groupID postID:postID text:text attachments:attachmentIDs mainAttachment:mainAttachmentID preview:preview isFavorite:NO] mutableCopy];
	
	if (lastKnownModificationDate) {
	
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

		NSString *lastKnownModificationDateString = [formatter stringFromDate:lastKnownModificationDate];
		[postEntity setObject:lastKnownModificationDateString forKey:@"last_update_time"];
	
	}
	
	[self.engine fireAPIRequestNamed:@"posts/update" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(postEntity, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (!successBlock)
			return;
		
		successBlock(
			[inResponseOrNil valueForKey:@"post"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) createCommentForPost:(NSString *)aPostIdentifier inGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	[self.engine fireAPIRequestNamed:@"posts/newComment" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		aPostIdentifier, @"post_id",
		contentTextOrNil, @"content",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (!successBlock)
			return;
		
		successBlock([inResponseOrNil objectForKey:@"post"]);

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrievePostsInGroup:(NSString *)aGroupIdentifier usingFilter:(id)aFilter onSuccess:(void(^)(NSArray *postReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

  NSParameterAssert(aGroupIdentifier);
  NSParameterAssert(aFilter);
  
  NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    aGroupIdentifier, @"group_id",
  nil];

  if ([aFilter isKindOfClass:[NSString class]]) {
    [arguments setObject:aFilter forKey:@"filter_id"];
  } else if ([aFilter isKindOfClass:[NSDictionary class]]) {
    [arguments setObject:[(NSDictionary *)aFilter JSONString] forKey:@"filter_entity"];
  }
  
  [self.engine fireAPIRequestNamed:@"posts/fetchByFilter" withArguments:arguments options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
  
    if (!successBlock)
      return;
    
    successBlock([inResponseOrNil objectForKey:@"posts"]);
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) createSharableSnapshotForPost:(NSString *)aPostIdentifier inGroup:(NSString *)aGroupIdentifier onSuccess:(void (^)(NSString *))successBlock onFailure:(void (^)(NSError *))failureBlock {

  NSParameterAssert(aPostIdentifier);
  NSParameterAssert(aGroupIdentifier);

	[self.engine fireAPIRequestNamed:@"posts/takeSnapshot" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		aPostIdentifier, @"post_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (!successBlock)
			return;
		
		successBlock([inResponseOrNil objectForKey:@"access_token"]);

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveSharableSnapshotForPost:(NSString *)aPostIdentifier usingToken:(NSString *)aToken onSuccess:(void(^)(NSDictionary *aPostRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

  NSParameterAssert(aPostIdentifier);
  NSParameterAssert(aToken);
  
  [self.engine fireAPIRequestNamed:@"posts/getSnapshot" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
  
    aPostIdentifier, @"post_id",
    aToken, @"access_token",
  
  nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
  
    if (!successBlock)
      return;
    
    successBlock([inResponseOrNil objectForKey:@"post"]);
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) configurePost:(NSString *)aPostIdentifier withVisibilityStatus:(BOOL)willBeVisible onSuccess:(void (^)(void))aSuccessBlock onFailure:(void (^)(NSError *))failureBlock {

  NSString *methodName = willBeVisible ? @"posts/hide" : @"posts/unhide";

	[self.engine fireAPIRequestNamed:methodName withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		aPostIdentifier, @"post_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (aSuccessBlock)
      aSuccessBlock();

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
