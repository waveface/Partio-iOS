//
//  WAFileExif+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 5/10/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFileExif+WARemoteInterfaceEntitySyncing.h"

@implementation WAFileExif (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
  
  return nil;
  
}

+ (BOOL) skipsNonexistantRemoteKey {
  
  return YES;
  
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {
  
  NSMutableDictionary *transformedRepresentation = [NSMutableDictionary dictionaryWithDictionary:incomingRepresentation];
  
  NSNumber *(^numberFromArray)(NSArray *array) = ^(NSArray *array) {
    if (array.count != 2)
      return [NSNumber numberWithInteger:0];
    return [NSNumber numberWithFloat:(float)([array[0] floatValue]/[array[1] floatValue])];
  };
  
  NSArray *exposureTime = [transformedRepresentation valueForKey:@"ExposureTime"];
  if (exposureTime) {
    [transformedRepresentation setValue:numberFromArray(exposureTime) forKey:@"ExposureTime"];
  }
  
  NSArray *fnumber = [transformedRepresentation valueForKey:@"FNumber"];
  if (fnumber) {
    [transformedRepresentation setValue:numberFromArray(fnumber) forKey:@"FNumber"];
  }
  
  NSArray *apertureValue = [transformedRepresentation valueForKey:@"ApertureValue"];
  if (apertureValue) {
    [transformedRepresentation setValue:numberFromArray(apertureValue) forKey:@"ApertureValue"];
  }
  
  NSArray *focalLength = [transformedRepresentation valueForKey:@"FocalLength"];
  if (focalLength) {
    [transformedRepresentation setValue:numberFromArray(focalLength) forKey:@"FocalLength"];
  }
  
  NSLog(@"transform %@", transformedRepresentation);
  return transformedRepresentation;
  
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
  
  static NSDictionary *mapping = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    mapping = [NSDictionary dictionaryWithObjectsAndKeys:
               @"gpsLatitude", @"latitude",
               @"gpsLongitude", @"longitude",
               @"exposureTime", @"ExposureTime",
               @"fNumber", @"FNumber",
               @"colorSpace", @"ColorSpace",
               @"focalLength", @"FocalLength",
               @"flash", @"Flash",
               @"apertureValue", @"ApertureValue",
               @"isoSpeedRatings", @"ISOSpeedRatings",
               @"whiteBalance", @"WhiteBalance",
               nil];
    
  });
  
  return mapping;
  
}

@end
