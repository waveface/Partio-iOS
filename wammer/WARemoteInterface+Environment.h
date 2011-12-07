//
//  WARemoteInterface+Environment.h
//  wammer
//
//  Created by Evadne Wu on 12/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Environment)

- (BOOL) areExpensiveOperationsAllowed;  //  By default, if the station is available and the device is on WiFi, returns YESs

@end
