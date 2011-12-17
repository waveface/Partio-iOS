//
//  WAAppDelegate.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIWindow+IRAdditions.h"

@interface WAAppDelegate : NSObject

//	Network activity indications.
//	Stackable.  Not thread safe.  Must invoke on main thread.

- (void) beginNetworkActivity;
- (void) endNetworkActivity;

@end
