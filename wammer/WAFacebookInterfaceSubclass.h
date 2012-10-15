//
//  WAFacebookInterface_WAFacebookInterfaceSubclass.h
//  wammer
//
//  Created by Evadne Wu on 7/11/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFacebookInterface.h"
#import <FacebookSDK/FacebookSDK.h>

@interface WAFacebookInterface () //<FBSessionDelegate>

//@property (nonatomic, readonly, strong) Facebook *facebook;

- (NSArray *) copyRequestedPermissions;

- (void) bounceCallbackWithMethod:(NSString *)methodName userInfo:(NSDictionary *)userInfo;
- (void) assertNotReached;

@end
