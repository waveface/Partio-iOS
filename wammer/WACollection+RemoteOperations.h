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

// https://github.com/waveface/Wammer-Cloud/wiki/Collections-API

+ (WACollection *) create;
/* Create a Collection */

- (void) addObjects:(NSArray*)objects;
/* Add photos to Collection. */

@end

extern NSString *const kWACollectionUpdated;