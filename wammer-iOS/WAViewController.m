//
//  WAViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/10/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAViewController.h"

@implementation WAViewController

@synthesize onShouldAutorotateToInterfaceOrientation;

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	if (self.onShouldAutorotateToInterfaceOrientation)
		return self.onShouldAutorotateToInterfaceOrientation(interfaceOrientation);

	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void) dealloc {

	[onShouldAutorotateToInterfaceOrientation release];
	[super dealloc];

}

@end
