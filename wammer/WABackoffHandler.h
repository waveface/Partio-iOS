//
//  WABackoffHandler.h
//  wammer
//
//  Created by 冠凱 邱 on 12/6/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WAReachabilityDetector.h"

@interface WABackoffHandler : NSObject

- (id) initWithInitialBackoffInterval:(NSTimeInterval)interval;

@property (nonatomic, readonly, copy) WABackOffBlock backoffBlock;

@end
