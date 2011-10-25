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





@implementation WARemoteInterfaceContext

+ (WARemoteInterfaceContext *) context {

	NSString *preferredEndpointURLString = [[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointURL];
	NSURL *baseURL = [NSURL URLWithString:preferredEndpointURLString];
	return [[[self alloc] initWithBaseURL:baseURL] autorelease];
	
}

- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName {

	NSURL *returnedURL = [super baseURLForMethodNamed:inMethodName];
	
	//if ([inMethodName isEqualToString:@"authenticate"])
	//	returnedURL = [NSURL URLWithString:@"../../apidev/v1/auth/login/" relativeToURL:self.baseURL];
    
    if ([inMethodName isEqualToString:@"authenticate"])
		returnedURL = [NSURL URLWithString:@"auth/login/" relativeToURL:self.baseURL];
	
	if ([inMethodName isEqualToString:@"articles"])
		returnedURL = [NSURL URLWithString:@"posts/fetch_all/" relativeToURL:self.baseURL];
	
	if ([inMethodName isEqualToString:@"users"])
		returnedURL = [NSURL URLWithString:@"users/fetch_all/" relativeToURL:self.baseURL];
		
	if ([inMethodName isEqualToString:@"createArticle"])
		returnedURL = [NSURL URLWithString:@"post/create_new_post/" relativeToURL:self.baseURL];
		
	if ([inMethodName isEqualToString:@"createFile"])
		returnedURL = [NSURL URLWithString:@"file/upload_file/" relativeToURL:self.baseURL];
		
	if ([inMethodName isEqualToString:@"createComment"])
		returnedURL = [NSURL URLWithString:@"post/create_new_comment/" relativeToURL:self.baseURL];
	
	if ([inMethodName isEqualToString:@"lastReadArticleContext"])
		returnedURL = [NSURL URLWithString:@"users/latest_read_post_id/" relativeToURL:self.baseURL];
		
	return returnedURL;

}

@end





static NSString *waErrorDomain = @"com.waveface.wammer.remoteInterface.error";

@interface WARemoteInterface ()

+ (JSONDecoder *) sharedDecoder;

@property (nonatomic, readwrite, retain) NSTimer *dataRetrievalTimer;
@property (nonatomic, readwrite, assign) int dataRetrievalTimerPostponingCount;
@property (nonatomic, readwrite, assign) int automaticRemoteUpdatesPerformingCount;

@end

@implementation WARemoteInterface

@synthesize userIdentifier, userToken, defaultBatchSize;
@synthesize dataRetrievalBlocks, dataRetrievalInterval, nextRemoteDataRetrievalFireDate;
@synthesize dataRetrievalTimer, dataRetrievalTimerPostponingCount;
@synthesize performingAutomaticRemoteUpdates, automaticRemoteUpdatesPerformingCount;

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

- (void) dealloc {

	[dataRetrievalBlocks release];
	[nextRemoteDataRetrievalFireDate release];
	
	[super dealloc];

}

- (id) init {

	IRWebAPIEngine *engine = [[[IRWebAPIEngine alloc] initWithContext:[WARemoteInterfaceContext context]] autorelease];	
	
	[engine.globalRequestPreTransformers addObject:[[ ^ (NSDictionary *inOriginalContext) {
		dispatch_async(dispatch_get_main_queue(), ^ { [((WAAppDelegate *)[UIApplication sharedApplication].delegate) beginNetworkActivity]; });
		return inOriginalContext;
	} copy] autorelease]];
	
	[engine.globalRequestPreTransformers addObject:[[ ^ (NSDictionary *inOriginalContext) {
			
		if (self.userToken && self.userIdentifier) {

				NSMutableDictionary *mutatedContext = [[inOriginalContext mutableCopy] autorelease];
				NSMutableDictionary *originalFormMultipartFields = [inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
				
				if (originalFormMultipartFields) {
				
					NSMutableDictionary *mutatedFormMultipartFields = [[originalFormMultipartFields mutableCopy] autorelease];
					[mutatedContext setObject:mutatedFormMultipartFields forKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
					[mutatedFormMultipartFields setObject:self.userIdentifier forKey:@"creator_id"];
					[mutatedFormMultipartFields setObject:self.userToken forKey:@"token"];
					
				} else {
				
					NSDictionary *originalQueryParams = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
					NSMutableDictionary *mutatedQueryParams = [[originalQueryParams mutableCopy] autorelease];
					
					if (!mutatedQueryParams)
							mutatedQueryParams = [NSMutableDictionary dictionary];
					
					[mutatedContext setObject:mutatedQueryParams forKey:kIRWebAPIEngineRequestHTTPQueryParameters];
					[mutatedQueryParams setObject:self.userIdentifier forKey:@"creator_id"];
					[mutatedQueryParams setObject:self.userToken forKey:@"token"];
				
				}
				
				return (NSDictionary *)mutatedContext;
				
		}
	
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
	
	} copy] autorelease]];
	
	[engine.globalRequestPreTransformers addObject:[[engine class] defaultFormMultipartTransformer]];
	[engine.globalResponsePostTransformers addObject:[[engine class] defaultCleanUpTemporaryFilesResponseTransformer]];
	
	engine.parser = ^ (NSData *incomingData) {
	
		NSError *parsingError = nil;
		id anObject = [[WARemoteInterface sharedDecoder] objectWithData:incomingData error:&parsingError];
		
		if (!anObject) {
			NSLog(@"Error parsing: %@", parsingError);
			NSLog(@"Original content is %@", incomingData);
			return (NSDictionary *)nil;
		}
		
		return (NSDictionary *)([anObject isKindOfClass:[NSDictionary class]] ? anObject : [NSDictionary dictionaryWithObject:anObject forKey:@"response"]);
	
	};

	self = [self initWithEngine:engine authenticator:nil];
	if (!self)
		return nil;
	
	self.defaultBatchSize = 200;
	self.dataRetrievalInterval = 30;
	
	[self addRepeatingDataRetrievalBlocks:[self defaultDataRetrievalBlocks]];
	[self rescheduleAutomaticRemoteUpdates];
	
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

- (void) rescheduleAutomaticRemoteUpdates {

	[self.dataRetrievalTimer invalidate];
	self.dataRetrievalTimer = nil;

	self.dataRetrievalTimer = [NSTimer scheduledTimerWithTimeInterval:self.dataRetrievalInterval target:self selector:@selector(handleDataRetrievalTimerDidFire:) userInfo:nil repeats:NO];

}

- (void) performAutomaticRemoteUpdatesNow {

	[self.dataRetrievalTimer fire];
	[self.dataRetrievalTimer invalidate];
	[self rescheduleAutomaticRemoteUpdates];

}

- (void) handleDataRetrievalTimerDidFire:(NSTimer *)timer {

	[self.dataRetrievalBlocks irExecuteAllObjectsAsBlocks];
	[self rescheduleAutomaticRemoteUpdates];

}

- (void) beginPostponingDataRetrievalTimerFiring {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}
	
	[self willChangeValueForKey:@"isPostponingDataRetrievalTimerFiring"];
	self.dataRetrievalTimerPostponingCount = self.dataRetrievalTimerPostponingCount + 1;
	[self didChangeValueForKey:@"isPostponingDataRetrievalTimerFiring"];
	
	if (self.dataRetrievalTimerPostponingCount == 1) {
		[self.dataRetrievalTimer invalidate];
		self.dataRetrievalTimer = nil;
	}

}

- (void) endPostponingDataRetrievalTimerFiring {
	
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}

	NSParameterAssert(self.dataRetrievalTimerPostponingCount);
	[self willChangeValueForKey:@"isPostponingDataRetrievalTimerFiring"];
	self.dataRetrievalTimerPostponingCount = self.dataRetrievalTimerPostponingCount - 1;
	[self didChangeValueForKey:@"isPostponingDataRetrievalTimerFiring"];
	
	if (!self.dataRetrievalTimerPostponingCount) {
		[self rescheduleAutomaticRemoteUpdates];
	}

}

- (BOOL) isPostponingDataRetrievalTimerFiring {

	return !!(self.dataRetrievalTimerPostponingCount);

}

- (void) beginPerformingAutomaticRemoteUpdates {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}
	
	[self willChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
	self.automaticRemoteUpdatesPerformingCount = self.automaticRemoteUpdatesPerformingCount + 1;
	[self didChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];

}

- (void) endPerformingAutomaticRemoteUpdates {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}

	NSParameterAssert(self.dataRetrievalTimerPostponingCount);
	
	[self willChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
	self.automaticRemoteUpdatesPerformingCount = self.automaticRemoteUpdatesPerformingCount - 1;
	[self didChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
	
}

- (BOOL) isPerformingAutomaticRemoteUpdates {

	return !!(self.automaticRemoteUpdatesPerformingCount);

}

- (NSArray *) defaultDataRetrievalBlocks {

	__block __typeof__(self) nrSelf = self;

	return [NSArray arrayWithObjects:
	
		[[ ^ {

			[nrSelf beginPerformingAutomaticRemoteUpdates];		
			[nrSelf beginPostponingDataRetrievalTimerFiring];
		
			[nrSelf retrieveLastReadArticleRemoteIdentifierOnSuccess: ^ (NSString *lastID, NSDate *modDate) {
				
				[[WADataStore defaultStore] updateUsersOnSuccess: ^ {
				
					[[WADataStore defaultStore] updateArticlesOnSuccess: ^ {
					
						[nrSelf endPerformingAutomaticRemoteUpdates];		
						[nrSelf endPostponingDataRetrievalTimerFiring];
					
					} onFailure: ^ {
					
						[nrSelf endPerformingAutomaticRemoteUpdates];		
						[nrSelf endPostponingDataRetrievalTimerFiring];
					
					}];
				
				} onFailure: ^ {
				
					[nrSelf endPerformingAutomaticRemoteUpdates];		
					[nrSelf endPostponingDataRetrievalTimerFiring];
				
				}];
		
			} onFailure: ^ (NSError *error) {
			
				[nrSelf endPerformingAutomaticRemoteUpdates];		
				[nrSelf endPostponingDataRetrievalTimerFiring];
			
			}];
	
		} copy] autorelease],
	
	nil];

}

- (void) addRepeatingDataRetrievalBlock:(void(^)(void))aBlock {

	[[self mutableArrayValueForKey:@"dataRetrievalBlocks"] irEnqueueBlock:aBlock];

}

- (void) addRepeatingDataRetrievalBlocks:(NSArray *)blocks{

	for (void(^aBlock)(void) in blocks)
		[self addRepeatingDataRetrievalBlock:aBlock];

}

@end





@implementation WADataStore (WARemoteInterfaceAdditions)

- (void) updateUsersWithCompletion:(void(^)(void))aBlock {

	[self updateUsersOnSuccess:aBlock onFailure:aBlock];

}

- (void) updateUsersOnSuccess:(void(^)(void))successBlock onFailure:(void(^)(void))failureBlock {

	[[WARemoteInterface sharedInterface] retrieveAvailableUsersOnSuccess:^(NSArray *retrievedUserReps) {
		
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
		
		[WAUser insertOrUpdateObjectsIntoContext:context withExistingProperty:@"identifier" matchingKeyPath:@"id" ofRemoteDictionaries:retrievedUserReps];
	
		NSError *savingError = nil;
		if (![context save:&savingError])
			NSLog(@"Saving failed: %@", savingError);
		
		if (successBlock)
			successBlock();
		
	} onFailure: ^ (NSError *error) {
	
		if (failureBlock)
				failureBlock();
		
	}];

}

- (void) updateArticlesWithCompletion:(void(^)(void))aBlock {

	[self updateArticlesOnSuccess:aBlock onFailure:aBlock];

}

- (void) updateArticlesOnSuccess:(void (^)(void))successBlock onFailure:(void (^)(void))failureBlock {
	
	[[WARemoteInterface sharedInterface] retrieveArticlesWithContinuation:nil batchLimit:[WARemoteInterface sharedInterface].defaultBatchSize onSuccess:^(NSArray *retrievedArticleReps) {
	
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
		
		[WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[retrievedArticleReps irMap: ^ (NSDictionary *inUserRep, NSUInteger index, BOOL *stop) {
		
			NSMutableDictionary *mutatedRep = [[inUserRep mutableCopy] autorelease];
			
			if ([mutatedRep objectForKey:@"id"]) {
				[mutatedRep setObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[inUserRep objectForKey:@"creator_id"], @"id",
				nil] forKey:@"owner"];
			}
			
			NSArray *commentReps = [mutatedRep objectForKey:@"comments"];
			if (commentReps) {
			
				[mutatedRep setObject:[commentReps irMap: ^ (NSDictionary *aCommentRep, NSUInteger index, BOOL *stop) {
				
					NSMutableDictionary *mutatedCommentRep = [[aCommentRep mutableCopy] autorelease];
					
					if ([aCommentRep objectForKey:@"creator_id"]) {
						[mutatedCommentRep setObject:[NSDictionary dictionaryWithObjectsAndKeys:
							[aCommentRep objectForKey:@"creator_id"], @"id",
						nil] forKey:@"owner"];
					}
					
					return mutatedCommentRep;
					
				}] forKey:@"comments"];
			
			}
		
			return mutatedRep;
			
		}] usingMapping:[NSDictionary dictionaryWithObjectsAndKeys:
		
			@"WAFile", @"files",
			@"WAComment", @"comments",
			@"WAUser", @"owner",
			@"WAPreview", @"previews",
		
		nil] options:IRManagedObjectOptionIndividualOperations];
		
		NSError *savingError = nil;
		if (![context save:&savingError])
			NSLog(@"Saving Error %@", savingError);
		
		if (successBlock)
			successBlock();
		
	} onFailure: ^ (NSError *error) {
		
		if (failureBlock)
			failureBlock();
		
	}];

}

- (void) uploadArticle:(NSURL *)anArticleURI withCompletion:(void(^)(void))aBlock {

	[self uploadArticle:anArticleURI onSuccess:aBlock onFailure:aBlock];

}

- (void) uploadArticle:(NSURL *)anArticleURI onSuccess:(void (^)(void))successBlock onFailure:(void (^)(void))failureBlock {

	NSParameterAssert(anArticleURI);

	NSString *currentUserIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:kWALastAuthenticatedUserIdentifier];
	
	NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
	WAArticle *updatedArticle = (WAArticle *)[context irManagedObjectForURI:anArticleURI];
			
	void (^uploadArticleIfAppropriate)(NSURL *articleURL) = ^ (NSURL *articleURL) {
	
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		WAArticle *updatedArticle = (WAArticle *)[context irManagedObjectForURI:articleURL];
		
		NSMutableArray *remoteFileIdentifiers = [NSMutableArray array];
		
		for (NSURL *aFileObjectURI in updatedArticle.fileOrder) {
			WAFile *aFile = (WAFile *)[context irManagedObjectForURI:aFileObjectURI];
			if (!aFile.identifier) {
				NSLog(@"Article file %@ does not have a remote identifier; bailing upload pending future invocation.", aFile);
				return;
			}
			[remoteFileIdentifiers addObject:aFile.identifier];
		}
		
		[[WARemoteInterface sharedInterface] createArticleAsUser:currentUserIdentifier withText:updatedArticle.text attachments:remoteFileIdentifiers usingDevice:[UIDevice currentDevice].model onSuccess:^(NSDictionary *createdCommentRep) {
		
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			NSArray *touchedArticles = [WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObject:createdCommentRep] usingMapping:[NSDictionary dictionaryWithObjectsAndKeys:
	
				@"WAFile", @"files",
				@"WAComment", @"comments",
				@"WAUser", @"owner",
				@"WAPreview", @"previews",
			
			nil] options:IRManagedObjectOptionIndividualOperations];
			
			for (WAArticle *anArticle in touchedArticles) {
				anArticle.draft = (NSNumber *)kCFBooleanFalse;
				NSLog(@"article %@, previews %@", anArticle, anArticle.previews);
			}
			
			if (successBlock)
				successBlock();
			
		} onFailure:^(NSError *error) {
		
			NSLog(@"Fail %@", error);
			
			if (failureBlock)
				failureBlock();
			
		}];

	};
	
	if (![updatedArticle.fileOrder count]) {
	
		//	If there are no attachments, all the merry
		//	Just send the article out and call it done.
		
		uploadArticleIfAppropriate(anArticleURI);
		return;
		
	}
	
	
	//	Otherwise, work up a queue.
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_group_t group = dispatch_group_create();
	
	for (NSURL *aFileObjectURI in updatedArticle.fileOrder) {
	
		dispatch_group_async(group, queue, ^ {
		
			__block NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			__block WAFile *updatedFile = (WAFile *)[context irManagedObjectForURI:aFileObjectURI];
			
			dispatch_queue_t currentQueue = dispatch_get_current_queue();
			dispatch_retain(currentQueue);
			
			[[WARemoteInterface sharedInterface] uploadFileAtURL:[NSURL fileURLWithPath:updatedFile.resourceFilePath] asUser:currentUserIdentifier onSuccess:^(NSDictionary *uploadedFileRep) {
			
				//	Guarding against accidental crossing of thread boundaries
				context = (id)0x1;
				updatedFile = (id)0x1;
			
				NSManagedObjectContext *refreshingContext = [[WADataStore defaultStore] disposableMOC];
				refreshingContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
				
				WAFile *refreshedFile = (WAFile *)[refreshingContext irManagedObjectForURI:aFileObjectURI];
				[refreshedFile configureWithRemoteDictionary:uploadedFileRep];
				
				NSError *savingError = nil;
				if (![refreshingContext save:&savingError])
					NSLog(@"Error saving: %@", savingError);
					
				NSURL *articleURL = [[refreshedFile.article objectID] URIRepresentation];
				
				dispatch_async(currentQueue, ^ {
					uploadArticleIfAppropriate(articleURL);
				});
				
				dispatch_release(currentQueue);
				
			} onFailure:^(NSError *error) {
			
				//	Guarding against accidental crossing of thread boundaries
				context = (id)0x1;
				updatedFile = (id)0x1;
				
				//	if (failureBlock)
				//		failureBlock();
				
				NSLog(@"Failed uploading file: %@", error);
				NSLog(@"TBD: handle this gracefully");
				
			}];

		});
	
	}
	
	dispatch_release(group);

}

@end
