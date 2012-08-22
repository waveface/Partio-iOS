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
@property (nonatomic, readwrite, assign) BOOL fixed;
@end

@implementation WABackoffHandler
@synthesize initialValue = _initialValue;
@synthesize currentValue = _currentValue;
@synthesize fixed = _fixed;

- (id) initWithInitialBackoffInterval:(NSTimeInterval)interval valueFixed:(BOOL)fixed {
	
	self = [super init];
	if (!self)
		return nil;
	
	_initialValue = interval;
	_currentValue = interval;
	_fixed = fixed;
	
	return self;
	
}

- (NSTimeInterval)nextInterval
{
	if (self.fixed) {
		return self.initialValue;
	}
	
	if (self.currentValue < 512) {
		self.currentValue *= 2;
	}
	
	return (NSTimeInterval)(arc4random() % (int)round(self.currentValue));
}

- (NSTimeInterval)firstInterval
{
	self.currentValue = self.initialValue;
	return (NSTimeInterval)(arc4random() % (int)round(self.currentValue));
}

@end
