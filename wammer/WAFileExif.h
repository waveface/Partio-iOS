//
//  WAFileExif.h
//  wammer
//
//  Created by kchiu on 12/9/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAFile;

@interface WAFileExif : IRManagedObject

@property (nonatomic, retain) NSString * dateTimeOriginal;
@property (nonatomic, retain) NSString * dateTimeDigitized;
@property (nonatomic, retain) NSString * dateTime;
@property (nonatomic, retain) NSString * model;
@property (nonatomic, retain) NSString * make;
@property (nonatomic, retain) NSNumber * exposureTime;
@property (nonatomic, retain) NSNumber * fNumber;
@property (nonatomic, retain) NSNumber * apertureValue;
@property (nonatomic, retain) NSNumber * focalLength;
@property (nonatomic, retain) NSNumber * flash;
@property (nonatomic, retain) NSNumber * isoSpeedRatings;
@property (nonatomic, retain) NSNumber * colorSpace;
@property (nonatomic, retain) NSNumber * whiteBalance;
@property (nonatomic, retain) NSNumber * gpsLongitude;
@property (nonatomic, retain) NSNumber * gpsLatitude;
@property (nonatomic, retain) NSString * gpsDateStamp;
@property (nonatomic, retain) NSString * gpsTimeStamp;
@property (nonatomic, retain) WAFile *file;

@end
