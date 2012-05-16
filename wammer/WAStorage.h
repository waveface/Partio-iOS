//
//  WAStorage.h
//  wammer
//
//  Created by Evadne Wu on 5/16/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAUser;

@interface WAStorage : IRManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSDate * intervalEndDate;
@property (nonatomic, retain) NSDate * intervalStartDate;
@property (nonatomic, retain) NSNumber * numberOfDocumentsAllowedInInterval;
@property (nonatomic, retain) NSNumber * numberOfDocumentsCreatedInInterval;
@property (nonatomic, retain) NSNumber * numberOfObjectsAllowedInInterval;
@property (nonatomic, retain) NSNumber * numberOfObjectsCreatedInInterval;
@property (nonatomic, retain) NSNumber * numberOfPicturesAllowedInInterval;
@property (nonatomic, retain) NSNumber * numberOfPicturesCreatedInInterval;
@property (nonatomic, retain) NSNumber * numberOfObjectsInQueue;
@property (nonatomic, retain) NSNumber * numberOfUnsyncedObjectsInQueue;
@property (nonatomic, retain) NSNumber * queueStatus;
@property (nonatomic, retain) WAUser *owner;

@end
