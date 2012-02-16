//
//  WARemoteInterface+Posts.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Posts.h"

@implementation WARemoteInterface (Posts)

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
	
		NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
		formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
		formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		datum = [formatter stringFromDate:referencedDateOrNil];
	
	}
	
	[self.engine fireAPIRequestNamed:@"posts/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
		
		aGroupIdentifier, @"group_id",
		datum, @"datum",
    
                [NSString stringWithFormat:@"%@%lu", 
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
	
	NSString *usedType = @"text";
	
	NSMutableDictionary *sentData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
	
	nil];
	
	if (contentTextOrNil)
		[sentData setObject:IRWebAPIKitStringValue(contentTextOrNil) forKey:@"content"];
	
	if (attachmentIdentifiersOrNil) {
		[sentData setObject:[attachmentIdentifiersOrNil JSONString] forKey:@"attachment_id_array"];
		if ([attachmentIdentifiersOrNil count]) {
			usedType = @"image";
		}
	}
	
	if (aPreviewRep) {
		[sentData setObject:[aPreviewRep JSONString] forKey:@"preview"];
		usedType = @"link";
	}
	
	[sentData setObject:usedType forKey:@"type"];

	[self.engine fireAPIRequestNamed:@"posts/new" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(sentData, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
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
