//
//  WARemoteInterfaceEntitySyncing.h
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^WAEntitySyncCallback)(BOOL didFinish, NSManagedObjectContext *context, NSArray *objects, NSError *error);


@protocol WARemoteInterfaceEntitySyncing <NSObject>

//	Remote entity syncing ideally does these jobs:
//	
//	1)	spin up Remote Inteface calling, bail if error
//	2)	spin up a local managed object context on successful API results retrieval, bail if error
//	3)	run insert-or-update, bail if error
//	4)	save, bail if error

+ (void) synchronizeWithCompletion:(WAEntitySyncCallback)block;	//	For a collection
- (void) synchronizeWithCompletion:(WAEntitySyncCallback)block;	//	For an instance

+ (void) synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock;
- (void) synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock;

@end


extern BOOL WAIsSyncableObject (NSManagedObject <WARemoteInterfaceEntitySyncing> *anObject);
