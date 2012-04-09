//
//  WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "WARemoteInterfaceEntitySyncing.h"

BOOL WAIsSyncableObject (NSManagedObject <WARemoteInterfaceEntitySyncing> *anObject) {

	return (BOOL)(![anObject hasChanges] && ![[anObject objectID] isTemporaryID]);

}


id<NSCopying> const kWAMergePolicy = @"WAMergePolicy";

id const kWAErrorMergePolicy = @"WAErrorMergePolicy";
id const kWAMergeByPropertyRemoteTrumpMergePolicy = @"WAMergeByPropertyRemoteTrumpMergePolicy";
id const kWAMergeByPropertyLocalTrumpMergePolicy = @"WAMergeByPropertyLocalTrumpMergePolicy";
id const kWAOverwriteWithRemoteMergePolicy = @"WAOverwriteWithRemoteMergePolicy";
id const kWAOverwriteWithLocalMergePolicy = @"WAOverwriteWithLocalMergePolicy";
id const kWAOverwriteWithLatestMergePolicy = @"WAOverwriteWithLatestMergePolicy";
