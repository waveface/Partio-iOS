//
//  WAFileAccessLog.h
//  wammer
//
//  Created by kchiu on 12/12/12.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <CoreData+IRAdditions.h>

@class WADocumentDay, WAFile;

@interface WAFileAccessLog : IRManagedObject

@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSDate * accessTime;
@property (nonatomic, retain) WAFile *file;
@property (nonatomic, retain) WADocumentDay *day;

@end
