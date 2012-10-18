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
		[self setDateTimeOriginal:exifData[@"DateTimeOriginal"]];
		[self setDateTimeDigitized:exifData[@"DateTimeDigitized"]];
		[self setExposureTime:exifData[@"ExposureTime"]];
		[self setFNumber:exifData[@"FNumber"]];
		[self setApertureValue:exifData[@"ApertureValue"]];
		[self setFocalLength:exifData[@"FocalLength"]];
		[self setFlash:exifData[@"Flash"]];
		if (exifData[@"ISOSpeedRatings"] && [exifData[@"ISOSpeedRatings"] count] > 0) {
			[self setIsoSpeedRatings:exifData[@"ISOSpeedRatings"][0]];
		}
		[self setColorSpace:exifData[@"ColorSpace"]];
		[self setWhiteBalance:exifData[@"WhiteBalance"]];
	}
	if (tiffData) {
		[self setDateTime:tiffData[@"DateTime"] ];
		[self setModel:tiffData[@"Model"]];
		[self setMake:tiffData[@"Make"]];
	}
	if (gpsData) {
		[self setGpsLongitude:gpsData[@"Longitude"]];
		[self setGpsLatitude:gpsData[@"Latitude"]];
	}

}

@end
