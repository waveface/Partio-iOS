//
//  WAFileAccessLog.h
//  IRTextAttributor
//
//  Created by Shen Steven on 12/14/12.
//  Copyright (c) 2012 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreData+IRAdditions.h>

@class WADocumentDay, WAFile, WAWebpageDay;

@interface WAFileAccessLog : IRManagedObject

@property (nonatomic, retain) NSDate * accessTime;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) WADocumentDay *day;
@property (nonatomic, retain) WAFile *file;
@property (nonatomic, retain) WAWebpageDay *dayWebpages;

@end
