//
//  WAFileExif+WAAdditions.m
//  wammer
//
//  Created by kchiu on 12/10/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFileExif+WAAdditions.h"

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
		self.gpsDateStamp = gpsData[@"DateStamp"];
		self.gpsTimeStamp = gpsData[@"TimeStamp"];
	}

}

@end
