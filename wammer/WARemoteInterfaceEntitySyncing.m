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
