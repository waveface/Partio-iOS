//
//  WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterfaceEntitySyncing.h"

BOOL WAObjectEligibleForRemoteInterfaceEntitySyncing (NSManagedObject <WARemoteInterfaceEntitySyncing> *anObject) {

	return (BOOL)(![anObject hasChanges] && ![[anObject objectID] isTemporaryID]);

}
