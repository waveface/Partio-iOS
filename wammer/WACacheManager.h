//
//  WACacheManager.h
//  wammer
//
//  Created by kchiu on 12/10/8.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WACache.h"

@protocol WACacheManagerDelegate

- (BOOL)shouldPurgeCachedFile:(WACache *)cache;

@end

@interface WACacheManager : NSObject <NSCoding>

+ (WACacheManager *)sharedManager;
- (void)insertOrUpdateCacheWithRelationship:(NSURL *)relationshipURL filePath:(NSString *)filePath filePathKey:(NSString *)filePathKey;
- (void)clearPurgeableFilesIfNeeded;

@property (nonatomic, readwrite, weak) id<WACacheManagerDelegate> delegate;

@end
