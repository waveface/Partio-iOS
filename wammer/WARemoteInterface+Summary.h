//
//  WARemoteInterface+Summary.h
//  wammer
//
//  Created by Shen Steven on 2/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Summary)

- (void) retrieveSummariesSince:(NSDate*)startDate daysOffset:(NSInteger)daysOffset inGroup:(NSString*)anGroupIdentifier onSuccess:(void(^)(NSArray *summaries, BOOL hasMore))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
