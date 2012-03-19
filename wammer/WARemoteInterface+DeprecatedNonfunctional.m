//
//  WARemoteInterface+DeprecatedNonfunctional.m
//  wammer
//
//  Created by Evadne Wu on 11/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+DeprecatedNonfunctional.h"
#import "WARemoteInterface+ScheduledDataRetrieval.h"
#import "WADataStore.h"
#import "JSONKit.h"

@implementation WARemoteInterface (Deprecated_Nonfunctional)

- (IRWebAPIRequestContextTransformer) defaultV1AuthenticationSignatureBlock {

	__block __typeof__(self) nrSelf = self;
	
	return [[ ^ (NSDictionary *inOriginalContext) {
			
		if (nrSelf.userToken && nrSelf.userIdentifier) {

				NSMutableDictionary *mutatedContext = [[inOriginalContext mutableCopy] autorelease];
				NSMutableDictionary *originalFormMultipartFields = [inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
				
				if (originalFormMultipartFields) {
				
					NSMutableDictionary *mutatedFormMultipartFields = [[originalFormMultipartFields mutableCopy] autorelease];
					[mutatedContext setObject:mutatedFormMultipartFields forKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
					[mutatedFormMultipartFields setObject:nrSelf.userIdentifier forKey:@"creator_id"];
					[mutatedFormMultipartFields setObject:nrSelf.userToken forKey:@"token"];
					
				} else {
				
					NSDictionary *originalQueryParams = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
					NSMutableDictionary *mutatedQueryParams = [[originalQueryParams mutableCopy] autorelease];
					
					if (!mutatedQueryParams)
							mutatedQueryParams = [NSMutableDictionary dictionary];
					
					[mutatedContext setObject:mutatedQueryParams forKey:kIRWebAPIEngineRequestHTTPQueryParameters];
					[mutatedQueryParams setObject:nrSelf.userIdentifier forKey:@"creator_id"];
					[mutatedQueryParams setObject:nrSelf.userToken forKey:@"token"];
				
				}
				
				return (NSDictionary *)mutatedContext;
				
		}
	
		return inOriginalContext;
	
	} copy] autorelease];

}

- (IRWebAPIRequestContextTransformer) defaultV1QueryHack {

	__block __typeof__(self) nrSelf = self;
	
	return [[ ^ (NSDictionary *inOriginalContext) {
	
		//	Transforms example.com?queryparam=value&… to example.com/queryparam/value/…
	
		NSDictionary *queryParameters = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
		NSURL *requestURL = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
		
		if (![[requestURL host] isEqual:[nrSelf.engine.context.baseURL host]])
			return inOriginalContext;
		
		if (![[inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPMethod] isEqual:@"GET"])
			return inOriginalContext;
		
		NSMutableDictionary *returnedContext = [[inOriginalContext mutableCopy] autorelease];
		NSMutableString *transposedRequestParams = [NSMutableString string];
		[queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[transposedRequestParams appendFormat:@"%@/%@/", key, obj];
		}];
		
		[returnedContext setObject:[NSURL URLWithString:transposedRequestParams relativeToURL:requestURL] forKey:kIRWebAPIEngineRequestHTTPBaseURL];
		[returnedContext removeObjectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
		
		return (NSDictionary *)returnedContext;
	
	} copy] autorelease];
	
}

- (void) retrieveAvailableUsersOnSuccess:(void(^)(NSArray *retrievedUserReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	WARemoteInterfaceNotPorted();

	[self.engine fireAPIRequestNamed:@"users" withArguments:nil options:nil validator:^BOOL(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
		
		NSArray *userReps = [inResponseOrNil objectForKey:@"users"];
		return [userReps isKindOfClass:[NSArray class]];
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSArray *userReps = [inResponseOrNil objectForKey:@"users"];
	
		if (successBlock)
			successBlock(userReps);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveArticlesWithContinuation:(id)aContinuation batchLimit:(NSUInteger)maximumNumberOfArticles onSuccess:(void(^)(NSArray *retrievedArticleReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	WARemoteInterfaceNotPorted();

	[self beginPostponingDataRetrievalTimerFiring];

	[self.engine fireAPIRequestNamed:@"articles" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSNumber numberWithUnsignedInteger:maximumNumberOfArticles], @"limit",
		aContinuation, @"timestamp",
		
	nil] options:nil validator: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
		
		return [[inResponseOrNil objectForKey:@"posts"] isKindOfClass:[NSArray class]];
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		[self endPostponingDataRetrievalTimerFiring];

		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"posts"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
	
		[self endPostponingDataRetrievalTimerFiring];
	
		if (failureBlock)
			failureBlock(anError);
	
	})];

}

- (void) retrieveArticleWithRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *retrievedArticleRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {	

	WARemoteInterfaceNotPorted();
	
	[self.engine fireAPIRequestNamed:[@"article" stringByAppendingPathComponent:anIdentifier] withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"post"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];	

}

- (void) retrieveCommentsOfArticleWithRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSArray *retrievedComentReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	WARemoteInterfaceNotPorted();

	[self beginPostponingDataRetrievalTimerFiring];

	[self.engine fireAPIRequestNamed:[[@"article" stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:@"comments"] withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		[self endPostponingDataRetrievalTimerFiring];

		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"comments"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
	
		[self endPostponingDataRetrievalTimerFiring];
	
		if (failureBlock)
			failureBlock(anError);
	
	})];

}

- (void) createArticleAsUser:(NSString *)creatorIdentifier withText:(NSString *)bodyText attachments:(NSArray *)attachmentIdentifiers usingDevice:(NSString *)creationDeviceName onSuccess:(void(^)(NSDictionary *createdCommentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	WARemoteInterfaceNotPorted();

	[self.engine fireAPIRequestNamed:@"createArticle" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
	
			IRWebAPIKitStringValue(creatorIdentifier), @"creator_id",
			[UIDevice currentDevice].model, @"creation_device_name",
			IRWebAPIKitStringValue(bodyText), @"text",
			[attachmentIdentifiers JSONString], @"files",
		
		nil], kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
    
    return (BOOL)[[inResponseOrNil objectForKey:@"post"] isKindOfClass:[NSDictionary class]];
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"post"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
	
}

- (void) uploadFileAtURL:(NSURL *)aFileURL asUser:(NSString *)creatorIdentifier onSuccess:(void(^)(NSDictionary *uploadedFileRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	WARemoteInterfaceNotPorted();

	NSURL *movableFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:aFileURL];
	NSURL *newURL = [movableFileURL pathExtension] ? movableFileURL : [NSURL fileURLWithPath:[[[movableFileURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"]];

	if (![[newURL absoluteString] isEqual:[movableFileURL absoluteString]]) {
		NSError *movingError = nil;
		if (![[NSFileManager defaultManager] moveItemAtURL:movableFileURL toURL:newURL error:&movingError]) {
			NSLog(@"Error moving: %@ — using the old URI.", movingError);
		}
	}

	[self.engine fireAPIRequestNamed:@"createFile" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
		
			newURL, @"file_content",
			creatorIdentifier, @"creator_id",
			IRWebAPIKitStringValue([UIDevice currentDevice].model), @"creation_device_name",
			@"", @"text",
			@"public.image", @"type",
		
		nil], kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:^BOOL(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
		
		return ([[inResponseOrNil objectForKey:@"file"] isKindOfClass:[NSDictionary class]]);
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"file"]);
		
		[[NSFileManager defaultManager] removeItemAtURL:newURL error:nil];
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
	
		if (failureBlock)
			failureBlock(anError);
			
		[[NSFileManager defaultManager] removeItemAtURL:newURL error:nil];
	
	})];
	
}

- (void) createCommentAsUser:(NSString *)creatorIdentifier forArticle:(NSString *)anIdentifier withText:(NSString *)bodyText usingDevice:(NSString *)creationDeviceName onSuccess:(void(^)(NSDictionary *createdCommentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	WARemoteInterfaceNotPorted();

	[self.engine fireAPIRequestNamed:@"createComment" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
		
		[NSDictionary dictionaryWithObjectsAndKeys:
	
			creatorIdentifier, @"creator_id",
			[UIDevice currentDevice].model, @"creation_device_name",
			anIdentifier, @"post_id",
			bodyText, @"text",
		
		nil], kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"comment"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveLastReadArticleRemoteIdentifierOnSuccess:(void(^)(NSString *lastID, NSDate *modDate))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	if (successBlock)
		successBlock(nil, nil);
	
}

- (void) setLastReadArticleRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	if (successBlock)
		successBlock(nil);
	
}

@end
