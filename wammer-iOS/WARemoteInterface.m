//
//  WARemoteInterface.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "JSONKit.h"
#import "WARemoteInterface.h"
#import "IRWebAPIEngine.h"
#import "IRWebAPIEngine+FormMultipart.h"
#import "IRWebAPIEngine+LocalCaching.h"

#import "WAAppDelegate.h"





@interface WARemoteInterfaceContext : IRWebAPIContext

+ (WARemoteInterfaceContext *) context;

@end

@implementation WARemoteInterfaceContext

+ (WARemoteInterfaceContext *) context {

	NSURL *baseURL = [NSURL URLWithString:@"http://api.waveface.com:8080"];
	return [[[self alloc] initWithBaseURL:baseURL] autorelease];

}

- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName {

	NSURL *returnedURL = [super baseURLForMethodNamed:inMethodName];
	
	if ([inMethodName isEqualToString:@"articles"])
		returnedURL = [NSURL URLWithString:@"api/v1/posts/fetch_all" relativeToURL:self.baseURL];
	
	if ([inMethodName isEqualToString:@"users"])
		returnedURL = [NSURL URLWithString:@"api/v1/users/fetch_all" relativeToURL:self.baseURL];
	
	NSLog(@"returnedURL %@ %@", returnedURL, [returnedURL absoluteString]);
		
	return returnedURL;

}

@end





static NSString *waErrorDomain = @"com.waveface.wammer.remoteInterface.error";

@interface WARemoteInterface ()

+ (JSONDecoder *) sharedDecoder;

@end

@implementation WARemoteInterface

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

- (id) init {

	IRWebAPIEngine *engine = [[[IRWebAPIEngine alloc] initWithContext:[WARemoteInterfaceContext context]] autorelease];	
	
	[engine.globalRequestPreTransformers addObject:[[engine class] defaultFormMultipartTransformer]];
	[engine.globalResponsePostTransformers addObject:[[engine class] defaultCleanUpTemporaryFilesResponseTransformer]];
	
	[engine.globalRequestPreTransformers addObject:[[ ^ (NSDictionary *inOriginalContext) {
		dispatch_async(dispatch_get_main_queue(), ^ { [((WAAppDelegate *)[UIApplication sharedApplication].delegate) beginNetworkActivity]; });
		return inOriginalContext;
	} copy] autorelease]];
	
	[engine.globalResponsePostTransformers addObject:[[ ^ (NSDictionary *inParsedResponse, NSDictionary *inResponseContext) {
		dispatch_async(dispatch_get_main_queue(), ^ { [((WAAppDelegate *)[UIApplication sharedApplication].delegate) endNetworkActivity]; });
		return inParsedResponse;
	} copy] autorelease]];
	
	[engine.globalRequestPreTransformers addObject:[[ ^ (NSDictionary *inOriginalContext) {
	
		//	Transforms example.com?queryparam=value&… to example.com/queryparam/value/…
	
		NSDictionary *queryParameters = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
		NSURL *requestURL = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
		
		if (![[requestURL host] isEqual:[engine.context.baseURL host]])
			return inOriginalContext;
		
		NSMutableDictionary *returnedContext = [[inOriginalContext mutableCopy] autorelease];
		NSMutableString *transposedRequestParams = [NSMutableString string];
		[queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[transposedRequestParams appendFormat:@"%@/%@/", key, obj];
		}];
		
		[returnedContext setObject:[NSURL URLWithString:transposedRequestParams relativeToURL:requestURL] forKey:kIRWebAPIEngineRequestHTTPBaseURL];
		[returnedContext removeObjectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
		
		return returnedContext;
	
	} copy] autorelease]];
	
	engine.parser = ^ (NSData *incomingData) {
	
		NSError *parsingError = nil;
		id anObject = [[WARemoteInterface sharedDecoder] objectWithData:incomingData error:&parsingError];
		
		if (!anObject) {
			NSLog(@"Error parsing: %@", parsingError);
			return (NSDictionary *)nil;
		}
		
		return (NSDictionary *)([anObject isKindOfClass:[NSDictionary class]] ? anObject : [NSDictionary dictionaryWithObject:anObject forKey:@"response"]);
	
	};


	return [self initWithEngine:engine authenticator:nil];

}

- (void) retrieveAvailableUsersOnSuccess:(void(^)(NSArray *retrievedUserReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"users" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	nil] options:nil validator:^BOOL(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
		
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

	[self.engine fireAPIRequestNamed:@"articles" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSNumber numberWithUnsignedInteger:maximumNumberOfArticles], @"limit",
		aContinuation, @"timestamp",
		
	nil] options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"articles"]);
		
	} failureHandler:nil];

}

- (void) retrieveArticleWithRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *retrievedArticleRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {	
	[self.engine fireAPIRequestNamed:[@"article" stringByAppendingPathComponent:anIdentifier] withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"article"]);
		
	} failureHandler:nil];	

}

- (void) retrieveCommentsOfArticleWithRemoteIdentifier:(NSString *)anIdentifier onSuccess:(void(^)(NSArray *retrievedComentReps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:[[@"article" stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:@"comments"] withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"comments"]);
		
	} failureHandler:nil];

}

- (void) createArticleAsUser:(NSString *)creatorIdentifier withText:(NSString *)bodyText attachments:(NSArray *)attachmentIdentifiers usingDevice:(NSString *)creationDeviceName onSuccess:(void(^)(NSDictionary *createdCommentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"article" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
		
			creatorIdentifier, @"creator_id",
			@"iPad", @"creation_device_name",
			bodyText, @"text",
			[attachmentIdentifiers JSONString], @"files",
		
		nil], kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"article"]);
		
	} failureHandler:nil];
	
}

- (void) uploadFileAtURL:(NSURL *)aFileURL asUser:(NSString *)creatorIdentifier onSuccess:(void(^)(NSDictionary *uploadedFileRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"file" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
		
			aFileURL, @"file",
			creatorIdentifier, @"creator_id",
			@"public.item", @"type",
		
		nil], kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"file"]);
		
	} failureHandler:nil];
	
}

- (void) createCommentAsUser:(NSString *)creatorIdentifier forArticle:(NSString *)anIdentifier withText:(NSString *)bodyText usingDevice:(NSString *)creationDeviceName onSuccess:(void(^)(NSDictionary *createdCommentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"comment" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		creatorIdentifier, @"creator_id",
		@"iPad", @"creation_device_name",
		anIdentifier, @"article_id",
		bodyText, @"text",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:
		
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"comment"]);
		
	} failureHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (failureBlock)
			failureBlock([NSError errorWithDomain:waErrorDomain code:0 userInfo:inResponseOrNil]);
		
	}];

}

@end





@implementation WADataStore (WARemoteInterfaceAdditions)

- (void) updateUsersWithCompletion:(void(^)(void))aBlock {

	[[WARemoteInterface sharedInterface] retrieveAvailableUsersOnSuccess:^(NSArray *retrievedUserReps) {
		
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
		
		[WAUser insertOrUpdateObjectsIntoContext:context withExistingProperty:@"identifier" matchingKeyPath:@"id" ofRemoteDictionaries:retrievedUserReps];
	
		NSError *savingError = nil;
		if (![context save:&savingError])
			NSLog(@"Saving failed: %@", savingError);
		
		if (aBlock)
			aBlock();
		
	} onFailure:^(NSError *error) {
	
		//	Handle reload?
		
	}];

}

- (void) updateArticlesWithCompletion:(void(^)(void))aBlock {

	//	?
	
	[[WARemoteInterface sharedInterface] retrieveArticlesWithContinuation:nil batchLimit:200 onSuccess:^(NSArray *retrievedArticleReps) {
	
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
		
		[WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[retrievedArticleReps irMap: ^ (NSDictionary *inUserRep, int index, BOOL *stop) {
		
			NSMutableDictionary *mutatedRep = [[inUserRep mutableCopy] autorelease];
			
			if ([mutatedRep objectForKey:@"id"]) {
				[mutatedRep setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[inUserRep objectForKey:@"creator_id"], @"id",
				nil] forKey:@"owner"];
			}
			
			NSArray *commentReps = [mutatedRep objectForKey:@"comments"];
			if (commentReps) {
			
				[mutatedRep setObject:[commentReps irMap: ^ (NSDictionary *aCommentRep, int index, BOOL *stop) {
				
					NSMutableDictionary *mutatedCommentRep = [[aCommentRep mutableCopy] autorelease];
					
					if ([aCommentRep objectForKey:@"creator_id"]) {
						[mutatedCommentRep setObject:[NSDictionary dictionaryWithObjectsAndKeys:
							[aCommentRep objectForKey:@"creator_id"], @"id",
						nil] forKey:@"owner"];
					}
					
					return mutatedCommentRep;
					
					NSLog(@"mutatedCommentRep %@", mutatedCommentRep);
					
				}] forKey:@"comments"];
			
			}
		
			return mutatedRep;
			
		}] usingMapping:[NSDictionary dictionaryWithObjectsAndKeys:
		
			@"WAFile", @"files",
			@"WAComment", @"comments",
			@"WAUser", @"owner",
		
		nil] options:0];
		
		NSError *savingError = nil;
		if (![context save:&savingError])
			NSLog(@"Saving Error %@", savingError);
		
		if (aBlock)
			aBlock();
		
	} onFailure: ^ (NSError *error) {
		
		//	Currently a NO OP
		
	}];

}

@end
