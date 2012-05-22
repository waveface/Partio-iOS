//
//  WADiscreteLayoutArea.m
//  wammer
//
//  Created by Evadne Wu on 5/2/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscreteLayoutArea.h"

@implementation WADiscreteLayoutArea
@synthesize templateNameBlock;

- (id) copyWithZone:(NSZone *)zone {

	WADiscreteLayoutArea *copy = [super copyWithZone:zone];
	copy.templateNameBlock = self.templateNameBlock;
	
	return copy;

}

@end
