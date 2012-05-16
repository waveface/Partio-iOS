//
//  WABlobSyncManager.h
//  wammer
//
//  Created by Evadne Wu on 1/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WADataStore.h"


#ifndef __WABlobSyncManager__
#define __WABlobSyncManager__

enum {

	WABlobSyncManagerUnknownState = 0,
	WABlobSyncManagerInactiveState = 1,
	WABlobSyncManagerActiveState = 2

}; typedef NSUInteger WABlobSyncManagerState;

#endif


@interface WABlobSyncManager : NSObject

+ (id) sharedManager;

- (void) beginPostponingBlobSync;
- (void) endPostponingBlobSync;
- (BOOL) isPerformingBlobSync;

@property (readonly, assign) NSUInteger numberOfFiles;

@end


@interface WADataStore (BlobSyncingAdditions)

- (void) enumerateFilesWithSyncableBlobsInContext:(NSManagedObjectContext *)context usingBlock:(void(^)(WAFile *aFile, NSUInteger index, BOOL *stop))block;

@end
