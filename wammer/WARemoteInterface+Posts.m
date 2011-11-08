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
	
	[self.engine fireAPIRequestNamed:@"posts/getSingle" withArguments:WARemoteInterfaceRFC3986EncodedDictionary([NSDictionary dictionaryWithObjectsAndKeys:
		
		aGroupIdentifier, @"group_id",
		anIdentifier, @"post_id",
				
	nil]) options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
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
	
	[self.engine fireAPIRequestNamed:@"posts/getSingle" withArguments:WARemoteInterfaceRFC3986EncodedDictionary([NSDictionary dictionaryWithObjectsAndKeys:
		
		aGroupIdentifier, @"group_id",
		datum, @"datum",
		[NSNumber numberWithInt:positiveOrNegativeNumberOfPostsToExpandSearching], @"limit",
		@"", @"filter",
				
	nil]) options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"post"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveLatestPostsInGroup:(NSString *)aGroupIdentifier withBatchLimit:(NSUInteger)maxNumberOfReturnedPosts onSuccess:(void (^)(NSArray *))successBlock onFailure:(void (^)(NSError *))failureBlock {
	
	[self.engine fireAPIRequestNamed:@"posts/getLatest" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		[NSNumber numberWithUnsignedInt:maxNumberOfReturnedPosts], @"limit",
	
	nil] validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
			
		successBlock(
			[inResponseOrNil valueForKeyPath:@"posts"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) createPostInGroup:(NSString *)aGroupIdentifier withContentText:(NSString *)contentTextOrNil attachments:(NSArray *)attachmentIdentifiersOrNil preview:(NSDictionary *)aPreviewRep onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	NSParameterAssert(aGroupIdentifier);
	
	NSMutableDictionary *sentData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
	
	nil];
	
	if (contentTextOrNil)
		[sentData setObject:IRWebAPIKitStringValue(contentTextOrNil) forKey:@"content"];
	
	if (attachmentIdentifiersOrNil)
		[sentData setObject:[attachmentIdentifiersOrNil JSONString] forKey:@"attachment_id_array"];
	
	if (aPreviewRep)
		[sentData setObject:[aPreviewRep JSONString] forKey:@"preview"];

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
		
		successBlock(nil);

	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
