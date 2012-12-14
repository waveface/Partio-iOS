//
//  WADocumentDay.h
//  wammer
//
//  Created by kchiu on 12/12/12.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <CoreData+IRAdditions.h>

@interface WADocumentDay : IRManagedObject

@property (nonatomic, retain) NSDate * day;
@property (nonatomic, retain) NSSet * accessLogs;

@end
