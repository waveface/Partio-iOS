//
//  WASyncManager+FullQualityFileSync.h
//  wammer
//
//  Created by Evadne Wu on 6/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASyncManager.h"

@class IRAsyncOperation;
@interface WASyncManager (FullQualityFileSync)

- (IRAsyncOperation *) fullQualityFileSyncOperationPrototype;

- (void) countFilesWithCompletion:(void(^)(NSUInteger count))block;
- (void) countFilesInContext:(NSManagedObjectContext *)context withCompletion:(void(^)(NSUInteger count))block;

@property (nonatomic, readwrite, assign) NSUInteger numberOfFiles;

@end
