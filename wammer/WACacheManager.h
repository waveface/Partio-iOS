//
//  WACacheManager.h
//  wammer
//
//  Created by kchiu on 12/10/8.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WACacheManager : NSObject <NSCoding>

+ (WACacheManager *)sharedManager;

@end
