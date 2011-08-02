//
//  WAView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/1/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAView.h"

@implementation WAView

@synthesize onHitTestWithEvent, onPointInsideWithEvent, onLayoutSubviews;

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {

	if (self.onHitTestWithEvent) {
		UIView *ownAnswer = self.onHitTestWithEvent(point, event);
		if (ownAnswer)
			return ownAnswer;
	}
	
	return [super hitTest:point withEvent:event];

}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event {

	if (self.onPointInsideWithEvent)
		return onPointInsideWithEvent(point, event, [super pointInside:point withEvent:event]);
	
	return [super pointInside:point withEvent:event];
	
}

- (void) layoutSubviews {

	if (self.onLayoutSubviews)
		self.onLayoutSubviews();

}

- (void) dealloc {

	[onHitTestWithEvent release];
	[onPointInsideWithEvent release];
	[onLayoutSubviews release];
	[super dealloc];

}

@end
