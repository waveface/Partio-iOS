//
//  WARemoteInterface+Usertracks.m
//  wammer
//
//  Created by Evadne Wu on 3/26/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+Usertracks.h"
#import "WADataStore.h"

@implementation WARemoteInterface (Usertracks)

- (void) retrieveChangedArticlesSince:(NSDate *)date inGroup:(NSString *)groupID withEntities:(BOOL)includesEntities onSuccess:(void(^)(NSArray *changedArticleIDs, NSArray* changes, NSDate *continuation))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert([date isKindOfClass:[NSDate class]]);
	NSParameterAssert(groupID);

	NSString *dateString = [[WADataStore defaultStore] ISO8601StringFromDate:date];
	NSParameterAssert(dateString);

	[self.engine fireAPIRequestNamed:@"usertracks/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		groupID, @"group_id",
		[[WADataStore defaultStore] ISO8601StringFromDate:date], @"since",
		includesEntities ? @"true" : @"false", @"include_entities",

	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		NSArray *changedArticleIDs = [inResponseOrNil valueForKeyPath:@"post_id_list"];
		NSArray *changeOperations = [inResponseOrNil valueForKeyPath:@"usertrack_list"];
		NSString *continuationString = [inResponseOrNil valueForKeyPath:@"latest_timestamp"];
		
		if (![continuationString length])
			continuationString = nil;
		
		NSDate *continuation = [[WADataStore defaultStore] dateFromISO8601String:continuationString];
		
		if (successBlock)
			successBlock(changedArticleIDs, changeOperations, continuation);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveChangedArticlesSince:(NSDate *)date inGroup:(NSString *)groupID onProgress:(void(^)(NSArray *changedArticleReps))progressBlock onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(date);
	NSParameterAssert(groupID);

	__block void (^fetchAndProcessArticlesSince)(NSDate *) = [^ (NSDate *sinceDate) {

		[self retrieveChangedArticlesSince:sinceDate inGroup:groupID withEntities:NO onSuccess:^(NSArray *changedArticleIDs, NSArray *changes, NSDate *continuation) {
		
			if (![changedArticleIDs count] || !continuation || [continuation isEqual:sinceDate]) {
				
				if (successBlock)
					successBlock();
				
				fetchAndProcessArticlesSince = nil;
				
				return;
				
			}
			
			NSMutableArray *articleOperations = [NSMutableArray array];
			
			for (NSString *articleID in changedArticleIDs) {
			
				[articleOperations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock:^(IRAsyncOperationCallback callback) {
				
					[[WARemoteInterface sharedInterface] retrievePost:articleID inGroup:groupID onSuccess:^(NSDictionary *postRep){
					
						callback(postRep);
					
					} onFailure:^(NSError *error) {
					
						callback(error);
					
					}];
					
				} completionBlock:^(id results) {
				
					if ([results isKindOfClass:[NSDictionary class]])
						progressBlock([NSArray arrayWithObject:results]);
					
				}]];
			
			}
			
			[articleOperations addObject:[IRAsyncBarrierOperation operationWithWorkerBlock:^(IRAsyncOperationCallback callback) {
			
				callback((id)kCFBooleanTrue);
				
			} completionBlock:^(id results) {
			
				if (!results || [results isKindOfClass:[NSError class]]) {
				
					if (failureBlock)
						failureBlock(results);
				
				} else {
					
					fetchAndProcessArticlesSince(continuation);
					
				}
				
			}]];
			
			__block NSOperationQueue *articleOperationQueue = [[NSOperationQueue alloc] init];
			articleOperationQueue.maxConcurrentOperationCount = 1;
			
			[articleOperations enumerateObjectsUsingBlock:^(IRAsyncBarrierOperation *currentOp, NSUInteger idx, BOOL *stop) {
				
				if (idx != 0)
				if (idx != ([articleOperations count] - 1)) {
					IRAsyncBarrierOperation *lastOperation = [articleOperations objectAtIndex:(idx - 1)];
					[currentOp addDependency:lastOperation];
				}
				
			}];
			
			for (NSOperation *operation in articleOperations)
				[articleOperationQueue addOperation:operation];
			
		} onFailure:^(NSError *error) {
			
			if (failureBlock)
				failureBlock(error);
			
			fetchAndProcessArticlesSince = nil;
			
		}];
	
	} copy];
	
	fetchAndProcessArticlesSince(date);

}

@end
