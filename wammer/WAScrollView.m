//
//  WAScrollView.m
//  wammer
//
//  Created by Evadne Wu on 1/30/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAScrollView.h"

@implementation WAScrollView
@synthesize onTouchesShouldBeginWithEventInContentView;
@synthesize onTouchesShouldCancelInContentView;

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {

	BOOL superAnswer = [super touchesShouldBegin:touches withEvent:event inContentView:view];
	
	if (self.onTouchesShouldBeginWithEventInContentView)
		return self.onTouchesShouldBeginWithEventInContentView(touches, event, view);
	
	return superAnswer;

}

- (BOOL) touchesShouldCancelInContentView:(UIView *)view {

	BOOL superAnswer = [super touchesShouldCancelInContentView:view];
	
	if (self.onTouchesShouldCancelInContentView)
		return self.onTouchesShouldCancelInContentView(view);
	
	return superAnswer;

}

@end
