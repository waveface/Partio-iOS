//
//  WARemoteInterface+Footprints.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Footprints.h"
#import "Foundation+IRAdditions.h"

@implementation WARemoteInterface (Footprints)

- (void) retrieveLastScannedPostInGroup:(NSString *)anIdentifier onSuccess:(void(^)(NSString *lastScannedPostIdentifier))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"footprints/getLastScan" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"group_id",
	
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
		
		successBlock([inResponseOrNil valueForKeyPath:@"last_scan.post_id"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) updateLastScannedPostInGroup:(NSString *)aGroupIdentifier withPost:(NSString *)aPostIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"footprints/setLastScan" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		aPostIdentifier, @"post_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveLastReadInfoForPosts:(NSArray *)postIdentifiers inGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(NSDictionary *lastReadPostIdentifiersToTimestamps))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert([postIdentifiers count]);

	[self.engine fireAPIRequestNamed:@"footprints/getLastScan" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		[postIdentifiers JSONString], @"post_id_array",
	
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
	
		NSMutableDictionary *lastReadPostIdentifiersToTimestamps = [NSMutableDictionary dictionary];
		NSArray *incomingPostInfo = [inResponseOrNil valueForKey:@"last_reads"];
		if ([incomingPostInfo isKindOfClass:[NSArray class]]) {
			[incomingPostInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				[lastReadPostIdentifiersToTimestamps setObject:[obj valueForKey:@"timestamp"] forKey:[obj valueForKey:@"post_id"]];
			}];
		}
		
		successBlock(lastReadPostIdentifiersToTimestamps);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) updateLastReadInfoForPosts:(NSArray *)postIdentifiers inGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert([postIdentifiers count]);
	
	postIdentifiers = [postIdentifiers irMap: ^ (NSString *anIdentifier, NSUInteger index, BOOL *stop) {
		return [NSDictionary dictionaryWithObject:anIdentifier forKey:@"post_id"];
	}];

	[self.engine fireAPIRequestNamed:@"footprints/setLastRead" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		[postIdentifiers JSONString], @"last_read_input_array",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
