//
//  WABackoffHandler.m
//  wammer
//
//  Created by 冠凱 邱 on 12/6/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WABackoffHandler.h"

@interface WABackoffHandler ()
@property (nonatomic, readwrite, assign) NSTimeInterval initialValue;
@property (nonatomic, readwrite, assign) NSTimeInterval currentValue;
@end

@implementation WABackoffHandler
@synthesize initialValue = _initialValue;
@synthesize currentValue = _currentValue;

- (id) initWithInitialBackoffInterval:(NSTimeInterval)interval {
	
	self = [super init];
	if (!self)
		return nil;
	
	_initialValue = interval;
	_currentValue = interval;
	
	return self;
	
}

- (WABackOffBlock) backoffBlock {
	
	__weak WABackoffHandler *wSelf = self;
	
	return [ ^ (BOOL resetBackOff) {
		
		if (resetBackOff) {
			wSelf.currentValue = wSelf.initialValue;
			return (NSTimeInterval)(arc4random() % (int)round(wSelf.currentValue));
		}
		
		if (wSelf.currentValue  < 512) {
			wSelf.currentValue *= 2;
		}
		
		return (NSTimeInterval)(arc4random() % (int)round(wSelf.currentValue));
	
	} copy];
	
}

@end
