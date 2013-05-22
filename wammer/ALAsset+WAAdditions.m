//
//  ALAsset+WAAdditions.m
//  wammer
//
//  Created by kchiu on 12/12/20.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "ALAsset+WAAdditions.h"
#import "AssetsLibrary+IRAdditions.h"

@implementation ALAsset (WAAdditions)

- (void)makeThumbnailWithOptions:(WAThumbnailType)type completeBlock:(WAImageProcessComplete)didCompleteBlock {

  ALAssetRepresentation *representation = [self defaultRepresentation];

  [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
	
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
	  UIImage *scaledImage = [WAImageProcessing scaledImageWithUIImage:[UIImage imageWithCGImage:[representation fullResolutionImage]
																						   scale:1.0f
																					 orientation:irUIImageOrientationFromAssetOrientation([representation orientation])]
																  type:type];
	  didCompleteBlock(scaledImage);
	} else {
	  UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:[representation fullResolutionImage]
																  type:type
														   orientation:irUIImageOrientationFromAssetOrientation([representation orientation])];
	  didCompleteBlock(scaledImage);
	}
  }];

}

- (NSString *) temporaryFileURLBasePath {
  static NSString * path;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSError *error = nil;
    path = [[(NSURL *)[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject] path] stringByAppendingPathComponent:@"assets"];
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
  });

  return path;
}

- (UIImage *) cachedPresentableImage {
  
  NSString *cachedFilePath = [[self temporaryFileURLBasePath] stringByAppendingPathComponent:self.defaultRepresentation.filename];
  NSError *error = nil;
  NSData *imageData = [NSData dataWithContentsOfFile:cachedFilePath options:NSDataReadingMappedIfSafe error:&error];

  if (imageData) {
    UIImage *image = [UIImage imageWithData:imageData];
    return image;
  } else {
    
    __weak ALAsset *wSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [wSelf makeThumbnailWithOptions:WAThumbnailTypeSmall completeBlock:^(UIImage *image) {

        
        NSData *data = UIImageJPEGRepresentation(image, 0.85f);
        [wSelf willChangeValueForKey:@"cachedPresentableImage"];
        NSError *error = nil;
        [data writeToFile:cachedFilePath options:NSDataWritingFileProtectionNone error:&error];
        if (error) {
          NSLog(@"Fail to write file: %@", error);
        }
        [wSelf didChangeValueForKey:@"cachedPresentableImage"];
      }];
    });
    
    return [UIImage imageWithCGImage:self.thumbnail];
    
  }
}

- (CLLocation*) gpsLocation {
  NSDictionary *meta = [self defaultRepresentation].metadata;
  if (meta) {
    NSDictionary *gps = meta[@"{GPS}"];
    if (gps) {
      CLLocationCoordinate2D coordinate;
      coordinate.latitude = [(NSNumber*)[gps valueForKey:@"Latitude"] doubleValue];
      coordinate.longitude = [(NSNumber*)[gps valueForKey:@"Longitude"] doubleValue];
      if ([gps[@"LongitudeRef"] isEqualToString:@"W"]) {
        coordinate.longitude = -coordinate.longitude;
      }
      if ([gps[@"LatitudeRef"] isEqualToString:@"S"]) {
        coordinate.latitude = -coordinate.latitude;
      }
      
      CLLocationDistance altitude = [(NSNumber*)[gps valueForKey:@"Altitude"] doubleValue];
      
      return [[CLLocation alloc] initWithCoordinate:coordinate altitude:altitude horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
    }
  }
  
  return  nil;
}
@end
