//
//  WAFBGraphUser.h
//  wammer
//
//  Created by Greener Chen on 13/5/29.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FBGraphUser.h>

@protocol WAFBGraphUser <FBGraphUser>

@property (nonatomic, strong) NSString *email;

@end