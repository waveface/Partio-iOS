//
//  WACache.h
//  wammer
//
//  Created by kchiu on 12/10/8.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "CoreData+IRAdditions.h"

@class WAFile, WAOpenGraphElementImage;

@interface WACache : IRManagedObject

@property (nonatomic, retain) NSNumber * fileSize;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSString * filePathKey;
@property (nonatomic, retain) NSDate * lastAccessTime;
@property (nonatomic, retain) WAFile * file;
@property (nonatomic, retain) WAOpenGraphElementImage * ogimage;

@end
