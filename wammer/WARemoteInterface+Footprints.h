//
//  WARemoteInterface+Footprints.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Footprints)

//	GET footprints/getLastScan
- (void) retrieveLastScannedPostInGroup:(NSString *)anIdentifier onSuccess:(void(^)(NSString *lastScannedPostIdentifier))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST footprints/setLastScan
- (void) updateLastScannedPostInGroup:(NSString *)aGroupIdentifier withPost:(NSString *)aPostIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	GET footprints/getLastRead
- (void) retrieveLastReadInfoForPosts:(NSArray *)postIdentifiers inGroup:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *lastReadPostIdentifiersToTimestamps))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST footprints/setLastRead
- (void) updateLastReadInfoForPosts:(NSArray *)postIdentifiers inGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
