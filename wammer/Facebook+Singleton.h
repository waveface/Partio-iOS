//
//  Facebook+Singleton.h
//  wammer
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "Facebook.h"

#define kFBAccessTokenKey  @"FBAccessTokenKey"
#define kFBExpirationDateKey  @"FBExpirationDateKey"

@interface Facebook (Singleton) <FBSessionDelegate>

+ (Facebook *) sharedInstanceWithDelegate:(id<FBSessionDelegate>) delegate;
- (void) authorize;

@end
