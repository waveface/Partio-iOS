//
//  WANavigationController.m
//  wammer
//
//  Created by Evadne Wu on 10/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WANavigationController.h"

@implementation WANavigationController

@synthesize onViewDidLoad;

- (void) viewDidLoad {

	[super viewDidLoad];

	if (self.onViewDidLoad)
		self.onViewDidLoad(self);

}

- (void) dealloc {

	[onViewDidLoad release];
	[super dealloc];

}

@end
