//
//  WARemoteInterface.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "JSONKit.h"
#import "WARemoteInterface.h"
#import "IRWebAPIEngine.h"
#import "IRWebAPIEngine+FormMultipart.h"
#import "IRWebAPIEngine+LocalCaching.h"

#import "WAAppDelegate.h"

#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WARemoteInterfaceContext.h"
#import "WARemoteInterface+ScheduledDataRetrieval.h"

static NSString *waErrorDomain = @"com.waveface.wammer.remoteInterface.error";

@interface WARemoteInterface ()

+ (JSONDecoder *) sharedDecoder;
+ (id) decodedJSONObjectFromData:(NSData *)data;
+ (IRWebAPIResponseParser) defaultParser;

+ (IRWebAPIRequestContextTransformer) defaultBeginNetworkActivityTransformer;
+ (IRWebAPIResponseContextTransformer) defaultEndNetworkActivityTransformer;

- (IRWebAPIRequestContextTransformer) defaultV1AuthenticationSignatureBlock DEPRECATED_ATTRIBUTE;
- (IRWebAPIRequestContextTransformer) defaultV2AuthenticationSignatureBlock;

- (IRWebAPIRequestContextTransformer) defaultV1QueryHack DEPRECATED_ATTRIBUTE;

@end

@implementation WARemoteInterface

@synthesize userIdentifier, userToken, defaultBatchSize;
@synthesize apiKey;

+ (WARemoteInterface *) sharedInterface {

	static WARemoteInterface *returnedInterface = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
	
		returnedInterface = [[self alloc] init];
    
	});

	return returnedInterface;

}

+ (JSONDecoder *) sharedDecoder {

	static JSONDecoder *returnedDecoder = nil;
	static dispatch_once_t onceToken = 0;
	
	dispatch_once(&onceToken, ^{
		JKParseOptionFlags sloppy = JKParseOptionComments|JKParseOptionUnicodeNewlines|JKParseOptionLooseUnicode|JKParseOptionPermitTextAfterValidJSON;
		returnedDecoder = [JSONDecoder decoderWithParseOptions:sloppy];
		[returnedDecoder retain];
	});

	return returnedDecoder;

}

+ (id) decodedJSONObjectFromData:(NSData *)data {
	
	return [[self sharedDecoder] objectWithData:data];

}

+ (IRWebAPIResponseParser) defaultParser {

	__block __typeof__(self) nrSelf = self;

	return [[ ^ (NSData *incomingData) {
	
		NSError *parsingError = nil;
		id anObject = [[nrSelf sharedDecoder] objectWithData:incomingData error:&parsingError];
		
		if (!anObject) {
			NSLog(@"Error parsing: %@", parsingError);
			NSLog(@"Original content is %@", incomingData);
			return (NSDictionary *)nil;
		}
		
		return (NSDictionary *)([anObject isKindOfClass:[NSDictionary class]] ? anObject : [NSDictionary dictionaryWithObject:anObject forKey:@"response"]);
	
	} copy] autorelease];

}

+ (IRWebAPIRequestContextTransformer) defaultBeginNetworkActivityTransformer {

	return [[ ^ (NSDictionary *inOriginalContext) {
		dispatch_async(dispatch_get_main_queue(), ^ { [((WAAppDelegate *)[UIApplication sharedApplication].delegate) beginNetworkActivity]; });
		return inOriginalContext;
	} copy] autorelease];

}

+ (IRWebAPIResponseContextTransformer) defaultEndNetworkActivityTransformer {

	return [[ ^ (NSDictionary *inParsedResponse, NSDictionary *inResponseContext) {
		dispatch_async(dispatch_get_main_queue(), ^ { [((WAAppDelegate *)[UIApplication sharedApplication].delegate) endNetworkActivity]; });
		return inParsedResponse;
	} copy] autorelease];

}

- (void) dealloc {

	[apiKey release];
	
	[userIdentifier release];
	[userToken release];
		
	[super dealloc];

}

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

- (IRWebAPIRequestContextTransformer) defaultV2AuthenticationSignatureBlock {

	__block __typeof__(self) nrSelf = self;
	
	return [[ ^ (NSDictionary *inOriginalContext) {
			
		NSMutableDictionary *mutatedContext = [[inOriginalContext mutableCopy] autorelease];
		NSMutableDictionary *originalFormMultipartFields = [inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
		
		if (originalFormMultipartFields) {
		
			NSMutableDictionary *mutatedFormMultipartFields = [[originalFormMultipartFields mutableCopy] autorelease];
			[mutatedContext setObject:mutatedFormMultipartFields forKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
			
			if (nrSelf.apiKey)
				[mutatedFormMultipartFields setObject:nrSelf.apiKey forKey:@"apikey"];
			
			if (nrSelf.userToken)
				[mutatedFormMultipartFields setObject:nrSelf.userToken forKey:@"session_token"];
			
		} else {
		
			NSDictionary *originalQueryParams = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
			NSMutableDictionary *mutatedQueryParams = [[originalQueryParams mutableCopy] autorelease];
			
			if (!mutatedQueryParams)
					mutatedQueryParams = [NSMutableDictionary dictionary];
			
			[mutatedContext setObject:mutatedQueryParams forKey:kIRWebAPIEngineRequestHTTPQueryParameters];
			
			if (nrSelf.apiKey)
				[mutatedQueryParams setObject:nrSelf.apiKey forKey:@"apikey"];
			
			if (nrSelf.userToken)
				[mutatedQueryParams setObject:nrSelf.userToken forKey:@"session_token"];
		
		}
		
		return (NSDictionary *)mutatedContext;
	
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
		
		return returnedContext;
	
	} copy] autorelease];
	
}

- (id) init {

	self = [self initWithEngine:[[[IRWebAPIEngine alloc] initWithContext:[WARemoteInterfaceContext context]] autorelease] authenticator:nil];
	if (!self)
		return nil;
	
	self.defaultBatchSize = 200;
	self.dataRetrievalInterval = 30;
	self.apiKey = kWARemoteEndpointApplicationKey;
	
	[self addRepeatingDataRetrievalBlocks:[self defaultDataRetrievalBlocks]];
	[self rescheduleAutomaticRemoteUpdates];
	
	return self;

}

- (id) initWithEngine:(IRWebAPIEngine *)engine authenticator:(IRWebAPIAuthenticator *)inAuthenticator {

	self = [super initWithEngine:engine authenticator:inAuthenticator];
	if (!self)
		return nil;

	[engine.globalRequestPreTransformers addObject:[[self class] defaultBeginNetworkActivityTransformer]];
	[engine.globalResponsePostTransformers addObject:[[self class] defaultEndNetworkActivityTransformer]];
		
	[engine.globalRequestPreTransformers addObject:[self defaultV2AuthenticationSignatureBlock]];
	//	[engine.globalRequestPreTransformers addObject:[self defaultV1AuthenticationSignatureBlock]];
	//	[engine.globalRequestPreTransformers addObject:[self defaultV1QueryHack]];

	[engine.globalRequestPreTransformers addObject:[[engine class] defaultFormMultipartTransformer]];
	[engine.globalResponsePostTransformers addObject:[[engine class] defaultCleanUpTemporaryFilesResponseTransformer]];
	
	engine.parser = [[self class] defaultParser];
	
	return self;

}

- (void) retrieveTokenForUserWithIdentifier:(NSString *)anIdentifier password:(NSString *)aPassword onSuccess:(void(^)(NSDictionary *userRep, NSString *token))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(anIdentifier);
	NSParameterAssert(aPassword);

	[self.engine fireAPIRequestNamed:@"authenticate" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitRFC3986EncodedStringMake(anIdentifier), @"userid",
		IRWebAPIKitRFC3986EncodedStringMake(aPassword), @"password",
	
	nil] options:nil validator:^BOOL(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		if (![[inResponseOrNil objectForKey:@"token"] isKindOfClass:[NSString class]])
			return NO;
		
		if (![[inResponseOrNil objectForKey:@"creator_id"] isKindOfClass:[NSString class]])
			return NO;
		
		return YES;
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSString *incomingToken = (NSString *)[inResponseOrNil objectForKey:@"token"];
		NSString *incomingIdentifier = (NSString *)[inResponseOrNil objectForKey:@"creator_id"];
		
		if (successBlock) {
			successBlock(			
				[NSDictionary dictionaryWithObjectsAndKeys:
					incomingIdentifier, @"creator_id",
				nil], 
				incomingToken
			);
		}
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {

		if (failureBlock)
			failureBlock([inResponseContext objectForKey:kIRWebAPIEngineUnderlyingError]);
		
	}];

}

- (void) retrieveAvailableUsersOnSuccess:(void(^)(NSArray *retrievedUserReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"users" withArguments:nil options:nil validator:^BOOL(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
		
		NSArray *userReps = [inResponseOrNil objectForKey:@"users"];
		return [userReps isKindOfClass:[NSArray class]];
		
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSArray *userReps = [inResponseOrNil objectForKey:@"users"];
	
		if (successBlock)
			successBlock(userReps);
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (failureBlock)
			failureBlock(nil);

	}];

}

- (void) retrieveArticlesWithContinuation:(id)aContinuation batchLimit:(NSUInteger)maximumNumberOfArticles onSuccess:(void(^)(NSArray *retrievedArticleReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

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
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		[self endPostponingDataRetrievalTimerFiring];
		
		if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseOrNil]);
		
	}];

}

- (void) retrieveArticleWithRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *retrievedArticleRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {	
	
	[self.engine fireAPIRequestNamed:[@"article" stringByAppendingPathComponent:anIdentifier] withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"post"]);
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseOrNil]);
		
	}];	

}

- (void) retrieveCommentsOfArticleWithRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSArray *retrievedComentReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self beginPostponingDataRetrievalTimerFiring];

	[self.engine fireAPIRequestNamed:[[@"article" stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:@"comments"] withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		[self endPostponingDataRetrievalTimerFiring];

		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"comments"]);
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		[self endPostponingDataRetrievalTimerFiring];

		if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseOrNil]);
		
	}];

}

- (void) createArticleAsUser:(NSString *)creatorIdentifier withText:(NSString *)bodyText attachments:(NSArray *)attachmentIdentifiers usingDevice:(NSString *)creationDeviceName onSuccess:(void(^)(NSDictionary *createdCommentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

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
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseContext]);
		
	}];
	
}

- (void) uploadFileAtURL:(NSURL *)aFileURL asUser:(NSString *)creatorIdentifier onSuccess:(void(^)(NSDictionary *uploadedFileRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

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
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseOrNil]);
		
		[[NSFileManager defaultManager] removeItemAtURL:newURL error:nil];
		
	}];
	
}

- (void) createCommentAsUser:(NSString *)creatorIdentifier forArticle:(NSString *)anIdentifier withText:(NSString *)bodyText usingDevice:(NSString *)creationDeviceName onSuccess:(void(^)(NSDictionary *createdCommentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

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
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseOrNil]);
		
	}];

}

- (void) retrieveLastReadArticleRemoteIdentifierOnSuccess:(void(^)(NSString *lastID, NSDate *modDate))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"lastReadArticleContext" withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
    if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"latest_read_post_id"], [inResponseOrNil objectForKey:@"latest_read_post_timestamp"]);
		
	} failureHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseOrNil]);
		
	}];

}

- (void) setLastReadArticleRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	[self.engine fireAPIRequestNamed:@"lastReadArticleContext" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
		
		[NSDictionary dictionaryWithObjectsAndKeys:
	
			anIdentifier, @"post_id",
		
		nil], kIRWebAPIEngineRequestHTTPQueryParameters,
		
		@"GET", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	  
    if (successBlock)
			successBlock(inResponseOrNil);
		
	} failureHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
    if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseOrNil]);
		
	}];

}

@end
