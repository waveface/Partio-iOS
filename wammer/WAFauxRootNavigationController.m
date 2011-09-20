//
//  WAFauxRootNavigationController.m
//  wammer
//
//  Created by Evadne Wu on 9/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAFauxRootNavigationController.h"
#import "Foundation+IRAdditions.h"

@implementation WAFauxRootNavigationController
@synthesize onPoppingFauxRoot;

- (BOOL) navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {

	NSUInteger indexOfItem = [[self.viewControllers irMap: ^ (UIViewController *aVC, int index, BOOL *stop) {
		return aVC.navigationItem;
	}] indexOfObject:item];
	
	if (indexOfItem == 1) {
	
		if (self.onPoppingFauxRoot)
			self.onPoppingFauxRoot();
			
		return NO;
	
	}
	
	return YES;

}
 
- (void) dealloc {

	[onPoppingFauxRoot release];
	[super dealloc];

}

@end
