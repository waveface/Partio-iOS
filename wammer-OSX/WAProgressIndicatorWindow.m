//
//  WAProgressIndicatorWindow.m
//  wammer
//
//  Created by Evadne Wu on 12/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAProgressIndicatorWindow.h"

@implementation WAProgressIndicatorWindow
@synthesize progressIndicator;

+ (id) fromNib {

	NSArray *objects = nil;	
	if ([[[[NSNib alloc] initWithNibNamed:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]] autorelease] instantiateNibWithOwner:nil topLevelObjects:&objects]) {
		return [[[objects lastObject] retain] autorelease];
	}
	
	return nil;

}

- (void) awakeFromNib {

	[super awakeFromNib];	
	[self.progressIndicator startAnimation:nil];

}

@end
