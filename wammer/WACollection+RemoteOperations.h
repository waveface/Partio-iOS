//
//  WACollection+RemoteOperations.h
//  wammer
//
//  Created by jamie on 1/4/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WACollection.h"

@interface WACollection (RemoteOperations)

+ (void) refreshCollectionsWithCompletion:(void(^)(void))completionBlock;

@end

extern NSString *const kWACollectionUpdated;