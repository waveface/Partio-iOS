//
//  WAFileExif+WAAdditions.h
//  wammer
//
//  Created by kchiu on 12/10/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFileExif.h"

@interface WAFileExif (WAAdditions)

- (void)initWithExif:(NSDictionary *)exifData tiff:(NSDictionary *)tiffData gps:(NSDictionary *)gpsData;
- (NSDictionary *)remoteRepresentation;

@end
