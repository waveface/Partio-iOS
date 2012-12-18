//
//  WAWebpageDay.h
//  wammer
//
//  Created by Shen Steven on 12/14/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreData+IRAdditions.h>

@class WAFileAccessLog;

@interface WAWebpageDay : IRManagedObject

@property (nonatomic, retain) NSDate * day;
@property (nonatomic, retain) WAFileAccessLog *accessLogs;

@end
