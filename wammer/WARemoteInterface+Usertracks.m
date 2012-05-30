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

	NSDate *usedSinceDate = date ? date : [NSDate dateWithTimeIntervalSince1970:0];
	NSString *dateString = [[WADataStore defaultStore] ISO8601StringFromDate:usedSinceDate];
	
	[self.engine fireAPIRequestNamed:@"usertracks/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		groupID, @"group_id",
		(includesEntities ? @"true" : @"false"), @"include_entities",
		dateString, @"since",

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

- (void) retrieveChangedArticlesSince:(NSDate *)date inGroup:(NSString *)groupID onProgress:(void(^)(NSArray *changedArticleReps, NSDate *continuation))progressBlock onSuccess:(void(^)(NSDate *continuation))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(groupID);

	__block void (^fetchAndProcessArticlesSince)(NSDate *) = [^ (NSDate *sinceDate) {

		[self retrieveChangedArticlesSince:sinceDate inGroup:groupID withEntities:NO onSuccess:^(NSArray *changedArticleIDs, NSArray *changes, NSDate *continuation) {
		
			if (![changedArticleIDs count] || !continuation || [continuation isEqual:sinceDate]) {				
				
				if (successBlock)
					successBlock(continuation);
				
				fetchAndProcessArticlesSince = nil;
				
				return;
				
			}
			
			[self retrievePostsInGroup:groupID withIdentifiers:changedArticleIDs onSuccess:^(NSArray *postReps) {
			
				if (progressBlock)
					progressBlock(postReps, continuation);
					
				fetchAndProcessArticlesSince(continuation);
				
			} onFailure:^(NSError *error) {
			
				if (failureBlock)
					failureBlock(error);
				
			}];
			
		} onFailure:^(NSError *error) {
			
			if (failureBlock)
				failureBlock(error);
			
			fetchAndProcessArticlesSince = nil;
			
		}];
	
	} copy];
	
	fetchAndProcessArticlesSince(date);

}

@end
