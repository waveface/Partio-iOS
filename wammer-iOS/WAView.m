//
//  WAView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/1/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAView.h"

@implementation WAView

@synthesize onHitTestWithEvent;

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {

	if (self.onHitTestWithEvent)
		return self.onHitTestWithEvent;
	
	return [super hitTest:point withEvent:event];

}

- (void) dealloc {

	[onHitTestWithEvent release];
	[super dealloc];

}

@end
