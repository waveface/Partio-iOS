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

	NSParameterAssert(groupID);

	[self.engine fireAPIRequestNamed:@"usertracks/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		groupID, @"group_id",
		[[WADataStore defaultStore] ISO8601StringFromDate:date], @"since",

	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		NSArray *changedArticleIDs = [inResponseOrNil valueForKeyPath:@"post_id_list"];
		NSArray *changeOperations = [inResponseOrNil valueForKeyPath:@"usertrack_list"];
		NSDate *continuation = [inResponseOrNil valueForKeyPath:@"latest_timestamp"];
		
		if (successBlock)
			successBlock(changedArticleIDs, changeOperations, continuation);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
