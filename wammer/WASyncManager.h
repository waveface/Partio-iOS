//
//  WASyncManager.h
//  wammer
//
//  Created by Evadne Wu on 1/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WADataStore.h"

@class IRRecurrenceMachine;
@interface WASyncManager : NSObject

- (void) beginPostponingSync;
- (void) endPostponingSync;

- (void) performSyncNow;
- (void) reload;

@property (nonatomic, readonly, assign) NSUInteger numberOfFiles;
@property (nonatomic, readonly, strong) IRRecurrenceMachine *recurrenceMachine;
@property (nonatomic, readonly, strong) NSOperationQueue *fileSyncOperationQueue;
@property (nonatomic, readonly, strong) NSOperationQueue *fileMetadataSyncOperationQueue;

@end
