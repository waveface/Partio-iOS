//
//  WAGeoLocation.h
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface WAGeoLocation : NSObject

- (void) identifyLocation:(CLLocationCoordinate2D)coordinate onComplete:(void(^)(NSArray*))completeBlock onError:(void(^)(NSError*))failureBlock;

- (void) cancel;
@end
