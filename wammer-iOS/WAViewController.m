//
//  WAViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/10/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAViewController.h"

@implementation WAViewController

@synthesize onShouldAutorotateToInterfaceOrientation, onLoadview;

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	if (self.onShouldAutorotateToInterfaceOrientation)
		return self.onShouldAutorotateToInterfaceOrientation(interfaceOrientation);

	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void) loadView {

	if (self.onLoadview)
		self.onLoadview(self);
	else
		[super loadView];

}

- (void) dealloc {

	[onShouldAutorotateToInterfaceOrientation release];
	[onLoadview release];
	[super dealloc];

}

@end
