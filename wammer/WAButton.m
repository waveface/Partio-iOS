//
//  WAButton.m
//  wammer
//
//  Created by Evadne Wu on 1/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAButton.h"


@interface WAButton ()

- (void) waInit;

@end


@implementation WAButton
@synthesize action;

- (void) dealloc {

	[action release];
	[super dealloc];

}

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	[self waInit];
	
	return self;

}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	[self waInit];

}

- (void) handleAction:(id)sender {

	if (self.action)
		self.action();
	
}

- (void) waInit {

	[self addTarget:self action:@selector(handleAction:) forControlEvents:UIControlEventTouchUpInside];

}

@end
