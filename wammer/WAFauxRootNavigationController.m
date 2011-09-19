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

- (BOOL) navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {

	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, navigationBar, item);
	
	//	[self.viewControllers indexOfObject:]

	return YES;

}

- (UIViewController *) popViewControllerAnimated:(BOOL)animated {

	NSLog(@"%@ %s %x", self, __PRETTY_FUNCTION__, animated);
	
	return [super popViewControllerAnimated:animated];

}

- (NSArray *) popToViewController:(UIViewController *)viewController animated:(BOOL)animated  {

	NSLog(@"%@ %s %@ %x", self, __PRETTY_FUNCTION__, viewController, animated);
	
	return [super popToViewController:viewController animated:animated];

}
- (NSArray *) popToRootViewControllerAnimated:(BOOL)animated {

	NSLog(@"%@ %s %x", self, __PRETTY_FUNCTION__, animated);

	return [super popToRootViewControllerAnimated:animated];

}

@end
