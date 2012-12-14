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

- (void) retrieveChangesSince:(NSDate *)date inGroup:(NSString *)groupID withEntities:(BOOL)includesEntities onSuccess:(void(^)(NSArray *changedArticleIDs, NSArray *changedFileIDs, NSArray* changes, NSDate *continuation))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSDate *usedSinceDate = date ? date : [NSDate dateWithTimeIntervalSince1970:0];
	NSString *dateString = [[WADataStore defaultStore] ISO8601StringFromDate:usedSinceDate];
	
	[self.engine fireAPIRequestNamed:@"usertracks/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		groupID, @"group_id",
		(includesEntities ? @"true" : @"false"), @"include_entities",
		dateString, @"since",

	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		NSArray *changedArticleIDs = [inResponseOrNil valueForKeyPath:@"post_id_list"];
		NSArray *changedFileIDs = [inResponseOrNil valueForKeyPath:@"attachment_id_list"];
		NSArray *changeOperations = [inResponseOrNil valueForKeyPath:@"usertrack_list"];
		NSString *continuationString = [inResponseOrNil valueForKeyPath:@"latest_timestamp"];
		
		if (![continuationString length])
			continuationString = nil;
		
		NSDate *continuation = [[WADataStore defaultStore] dateFromISO8601String:continuationString];
		
		if (successBlock)
			successBlock(changedArticleIDs, changedFileIDs, changeOperations, continuation);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveChangesSince:(NSDate *)date inGroup:(NSString *)groupID onProgress:(void(^)(NSArray *changedArticleReps, NSDate *continuation))progressBlock onSuccess:(void(^)(NSDate *continuation))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(groupID);

	__block void (^fetchAndProcessArticlesSince)(NSDate *) = [^ (NSDate *sinceDate) {

		[self retrieveChangesSince:sinceDate inGroup:groupID withEntities:NO onSuccess:^(NSArray *changedArticleIDs, NSArray *changedFileIDs, NSArray *changes, NSDate *continuation) {
		
			if (![changedArticleIDs count] || !continuation || [continuation isEqual:sinceDate]) {				
				
				if (successBlock)
					successBlock(continuation);
				
				fetchAndProcessArticlesSince = nil;
				
				return;
				
			}

			__block NSMutableArray *sentChangedArticleIDs = [@[] mutableCopy];
			const NSUInteger MAX_CHANGED_ARTICLES_COUNT = 10;
			[changedArticleIDs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				[sentChangedArticleIDs addObject:obj];
				if ([sentChangedArticleIDs count] == MAX_CHANGED_ARTICLES_COUNT || idx == [changedArticleIDs count] - 1) {
					[self retrievePostsInGroup:groupID withIdentifiers:sentChangedArticleIDs onSuccess:^(NSArray *postReps) {
						
						if (progressBlock)
							progressBlock(postReps, continuation);

						if (idx == [changedArticleIDs count] - 1) {
							fetchAndProcessArticlesSince(continuation);
						}
						
					} onFailure:^(NSError *error) {
						
						if (failureBlock)
							failureBlock(error);
						
					}];
					[sentChangedArticleIDs removeAllObjects];
				}
			}];
			
			[changedFileIDs enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop) {

				NSManagedObjectContext *context = [[WADataStore defaultStore] autoUpdatingMOC];
				context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
				NSMutableDictionary *attach = [@{
																			 @"object_id": identifier,
																			 @"creator_id": [[WADataStore defaultStore] mainUserInContext:context],
//																			 @"timestamp": incomingRepresentation[@"event_time"],
																			 @"file_name": @"unknown.jpg",
																			 @"type": @"image",
																			 @"created": [NSNull null]
																			 } mutableCopy];

				// create an WAFile entry for updateAttachmentsMetaOnSuccess to batch retrieve attachment metas
				[WAFile insertOrUpdateObjectsUsingContext:context
															 withRemoteResponse:[NSArray arrayWithObject:attach]
																		 usingMapping:nil
																					options:IRManagedObjectOptionIndividualOperations];
				[context save:nil];

				
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
