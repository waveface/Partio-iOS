//
//  WARemoteInterfaceEntitySyncing.h
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WARemoteInterfaceEntitySyncing <NSObject>

//	Remote entity syncing spins up a local managed object context on successful API results retrieval
//	And the real stuff is merged back when the results arrive
//	The caller must save the context on its own

+ (void) synchronizeWithCompletion:(void(^)(BOOL didFinish, NSManagedObjectContext *temporalContext, NSArray *prospectiveUnsavedObjects, NSError *anError))completionBlock;	//	Syncs all the entities in “the world”
- (void) synchronizeWithCompletion:(void(^)(BOOL didFinish, NSManagedObjectContext *temporalContext, NSManagedObject *prospectiveUnsavedObject, NSError *anError))completionBlock;	//	Syncs the actual entity

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(void(^)(BOOL didFinish, NSManagedObjectContext *temporalContext, NSArray *prospectiveUnsavedObjects, NSError *anError))completionBlock;
- (void) synchronizeWithOptions:(NSDictionary *)options completion:(void(^)(BOOL didFinish, NSManagedObjectContext *temporalContext, NSManagedObject *prospectiveUnsavedObject, NSError *anError))completionBlock;

@end

//	This is provided for individual object implementations to be called within -synchronizeWithCompletion:
extern BOOL WAObjectEligibleForRemoteInterfaceEntitySyncing (NSManagedObject <WARemoteInterfaceEntitySyncing> *anObject);
