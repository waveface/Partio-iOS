//
//  WAFileExif+WAAdditions.m
//  wammer
//
//  Created by kchiu on 12/10/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFileExif+WAAdditions.h"

@implementation NSNumber (WAAdditions)

/* Convert NSNumber to rational value
 * ref: http://www.ics.uci.edu/~eppstein/numth/frap.c
 */
- (NSArray *) rationalValue {
  
  long m[2][2];
  double x, startx;
  const long MAXDENOM = 10000;
  long ai;
  
  startx = x = [self doubleValue];
  
  /* initialize matrix */
  m[0][0] = m[1][1] = 1;
  m[0][1] = m[1][0] = 0;
  
  /* loop finding terms until denom gets too big */
  while (m[1][0] *  ( ai = (long)x ) + m[1][1] <= MAXDENOM) {
    long t;
    t = m[0][0] * ai + m[0][1];
    m[0][1] = m[0][0];
    m[0][0] = t;
    t = m[1][0] * ai + m[1][1];
    m[1][1] = m[1][0];
    m[1][0] = t;
    if(x==(double)ai) break;     // AF: division by zero
    x = 1/(x - (double) ai);
    if(x>(double)0x7FFFFFFF) break;  // AF: representation failure
  }
  
  return @[[NSNumber numberWithLong:m[0][0]], [NSNumber numberWithLong:m[1][0]]];
  
}

@end


@implementation WAFileExif (WAAdditions)

- (void)initWithExif:(NSDictionary *)exifData tiff:(NSDictionary *)tiffData gps:(NSDictionary *)gpsData {
  
  if (exifData) {
    self.dateTimeOriginal = exifData[@"DateTimeOriginal"];
    self.dateTimeDigitized = exifData[@"DateTimeDigitized"];
    self.exposureTime = exifData[@"ExposureTime"];
    self.fNumber = exifData[@"FNumber"];
    self.apertureValue = exifData[@"ApertureValue"];
    self.focalLength = exifData[@"FocalLength"];
    self.flash = exifData[@"Flash"];
    if (exifData[@"ISOSpeedRatings"] && [exifData[@"ISOSpeedRatings"] count] > 0) {
      self.isoSpeedRatings = exifData[@"ISOSpeedRatings"][0];
    }
    self.colorSpace = exifData[@"ColorSpace"];
    self.whiteBalance = exifData[@"WhiteBalance"];
  }
  if (tiffData) {
    self.dateTime = tiffData[@"DateTime"];
    self.model = tiffData[@"Model"];
    self.make = tiffData[@"Make"];
  }
  if (gpsData) {
    self.gpsLongitude = gpsData[@"Longitude"];
    self.gpsLatitude = gpsData[@"Latitude"];
    if ([gpsData[@"LongitudeRef"] isEqualToString:@"W"]) {
      self.gpsLongitude = @(-[self.gpsLongitude doubleValue]);
    }
    if ([gpsData[@"LatitudeRef"] isEqualToString:@"S"]) {
      self.gpsLatitude = @(-[self.gpsLatitude doubleValue]);
    }
    self.gpsDateStamp = gpsData[@"DateStamp"];
    self.gpsTimeStamp = gpsData[@"TimeStamp"];
  }
  
}

- (NSDictionary *)remoteRepresentation {
  
  NSMutableDictionary *exifData = [[NSMutableDictionary alloc] init];
  
  if (self.dateTimeOriginal) {
    exifData[@"DateTimeOriginal"] = self.dateTimeOriginal;
  }
  if (self.dateTimeDigitized) {
    exifData[@"DateTimeDigitized"] = self.dateTimeDigitized;
  }
  if (self.dateTime) {
    exifData[@"DateTime"] = self.dateTime;
  }
  if (self.model) {
    exifData[@"Model"] = self.model;
  }
  if (self.make) {
    exifData[@"Make"] = self.make;
  }
  if (self.exposureTime) {
    exifData[@"ExposureTime"] = [self.exposureTime rationalValue];
  }
  if (self.fNumber) {
    exifData[@"FNumber"] = [self.fNumber rationalValue];
  }
  if (self.apertureValue) {
    exifData[@"ApertureValue"] = [self.apertureValue rationalValue];
  }
  if (self.focalLength) {
    exifData[@"FocalLength"] = [self.focalLength rationalValue];
  }
  if (self.flash) {
    exifData[@"Flash"] = self.flash;
  }
  if (self.isoSpeedRatings) {
    exifData[@"ISOSpeedRatings"] = self.isoSpeedRatings;
  }
  if (self.colorSpace) {
    exifData[@"ColorSpace"] = self.colorSpace;
  }
  if (self.whiteBalance) {
    exifData[@"WhiteBalance"] = self.whiteBalance;
  }
  if (self.gpsLongitude && self.gpsLatitude) {
    NSMutableDictionary *gpsDic = [@{@"longitude":self.gpsLongitude, @"latitude":self.gpsLatitude} mutableCopy];
    if (self.gpsDateStamp) {
      gpsDic[@"GPSDateStamp"] = self.gpsDateStamp;
    }
    if (self.gpsTimeStamp) {
      NSArray *timeFileds = [self.gpsTimeStamp componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":."]];
      gpsDic[@"GPSTimeStamp"] = @[[@([timeFileds[0] integerValue]) rationalValue],
      [@([timeFileds[1] integerValue]) rationalValue],
      [@([timeFileds[2] integerValue]) rationalValue]];
    }
    exifData[@"gps"] = gpsDic;
  }
  
  return exifData;
  
}

@end
