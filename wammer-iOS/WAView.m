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

	UIView *superAnswer = [super hitTest:point withEvent:event];

	if (self.onHitTestWithEvent) {
		UIView *ownAnswer = self.onHitTestWithEvent(point, event, superAnswer);
		if (ownAnswer)
			return ownAnswer;
	}
	
	return superAnswer;

}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event {

	BOOL superAnswer = [super pointInside:point withEvent:event];

	if (self.onPointInsideWithEvent)
		return onPointInsideWithEvent(point, event, superAnswer);
	
	return superAnswer;
	
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
