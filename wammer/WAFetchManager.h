//
//  WAFetchManager.h
//  wammer
//
//  Created by kchiu on 12/12/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IRRecurrenceMachine;
@interface WAFetchManager : NSObject

@property (nonatomic, readonly, strong) NSOperationQueue *articleFetchOperationQueue;
@property (nonatomic, readonly, strong) NSOperationQueue *fileMetadataFetchOperationQueue;
@property (nonatomic, readonly, strong) NSOperationQueue *collectionInsertOperationQueue;
@property (nonatomic, readonly, strong) NSDate *currentDate;
@property (nonatomic, readonly) BOOL isFetching;

- (void) beginPostponingFetch;
- (void) endPostponingFetch;
- (void) reload;
- (void) cancelAllOperations;

@end
