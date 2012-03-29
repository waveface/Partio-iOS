//
//  WARemoteInterface+Usertracks.h
//  wammer
//
//  Created by Evadne Wu on 3/26/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Usertracks)

- (void) retrieveChangedArticlesSince:(NSDate *)date inGroup:(NSString *)groupID withEntities:(BOOL)includesEntities onSuccess:(void(^)(NSArray *changedArticleIDs, NSArray* changes, NSDate *continuation))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	changes will be nil if 
//	continuation points to another date, which can be passed back to the base method for the next batch of objects

@end
