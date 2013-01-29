//
//  WACollection+RemoteOperations.h
//  wammer
//
//  Created by jamie on 1/4/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WACollection.h"

@class WARemoteInterface;

@interface WACollection (RemoteOperations)
// https://github.com/waveface/Wammer-Cloud/wiki/Collections-API

@property (nonatomic, strong) WARemoteInterface *interface;

+ (void) refreshCollectionsWithCompletion:(void(^)(void))completionBlock;

- (WACollection *) initWithName:(NSString*) name withFiles:(NSArray*) objectIDs inManagedObjectContext:(NSManagedObjectContext*) context;
- (void) addObjects:(NSArray *)objects;

@end

extern NSString *const kWACollectionUpdated;