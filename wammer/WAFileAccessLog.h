//
//  WAFileAccessLog.h
//  wammer
//
//  Created by Shen Steven on 12/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreData+IRAdditions.h>

@class WADocumentDay, WAFile, WAWebpageDay;

@interface WAFileAccessLog : IRManagedObject

@property (nonatomic, retain) NSDate * accessTime;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSString * accessSource;
@property (nonatomic, retain) WADocumentDay *day;
@property (nonatomic, retain) WAWebpageDay *dayWebpages;
@property (nonatomic, retain) WAFile *file;

@end
