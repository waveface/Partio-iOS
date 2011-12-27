//
//  WAView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/1/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAView.h"

@implementation WAView

@synthesize onHitTestWithEvent, onPointInsideWithEvent, onLayoutSubviews, onSizeThatFits;

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

	[super layoutSubviews];

	if (self.onLayoutSubviews)
		self.onLayoutSubviews();

}

- (CGSize) sizeThatFits:(CGSize)size {

	CGSize superSize = [super sizeThatFits:size];
	if (self.onSizeThatFits)
		return self.onSizeThatFits(size, superSize);
	
	return superSize;

}

- (void) dealloc {

	[onHitTestWithEvent release];
	[onPointInsideWithEvent release];
	[onLayoutSubviews release];
	[onSizeThatFits release];
	
	[super dealloc];

}

@end
