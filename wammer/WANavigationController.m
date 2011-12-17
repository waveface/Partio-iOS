//
//  WANavigationController.m
//  wammer
//
//  Created by Evadne Wu on 10/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WANavigationController.h"
#import "WANavigationBar.h"

@implementation WANavigationController

@synthesize onViewDidLoad;
@synthesize willPushViewControllerAnimated, didPushViewControllerAnimated;
@synthesize onDismissModalViewControllerAnimated;
@synthesize disablesAutomaticKeyboardDismissal;

+ (id) alloc {

  UIViewController *fauxVC = [[[UIViewController alloc] init] autorelease];
  WANavigationController *fauxNavController = [super alloc];
  fauxNavController = [[fauxNavController initWithRootViewController:fauxVC] autorelease];
  
  NSData *fauxNavCData = [NSKeyedArchiver archivedDataWithRootObject:fauxNavController];
  NSKeyedUnarchiver *unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:fauxNavCData] autorelease];
  [unarchiver setClass:[WANavigationBar class] forClassName:@"UINavigationBar"];

  return [[unarchiver decodeObjectForKey:@"root"] retain];
    
}

- (id) initWithRootViewController:(UIViewController *)presentedViewController {

	NSParameterAssert(!presentedViewController.navigationController);

  self = [super initWithRootViewController:presentedViewController];
  if (!self)
    return nil;
  
  [self setViewControllers:[NSArray arrayWithObject:presentedViewController]];
  return self;

}

- (void) viewDidLoad {

	[super viewDidLoad];

	if (self.onViewDidLoad)
		self.onViewDidLoad(self);

}

- (void) pushViewController:(UIViewController *)viewController animated:(BOOL)animated {

	if (self.willPushViewControllerAnimated)
		self.willPushViewControllerAnimated(self, viewController, animated);
    
  self.contentSizeForViewInPopover = viewController.contentSizeForViewInPopover;
		
	[super pushViewController:viewController animated:animated];

	if (self.didPushViewControllerAnimated)
		self.didPushViewControllerAnimated(self, viewController, animated);

}

- (void) dismissModalViewControllerAnimated:(BOOL)animated {

	[self retain];

	[super dismissModalViewControllerAnimated:animated];

	if (self.onDismissModalViewControllerAnimated)
		self.onDismissModalViewControllerAnimated(self, animated);
	
	[self autorelease];

}

- (void) dealloc {

	[onViewDidLoad release];
	[willPushViewControllerAnimated release];
	[didPushViewControllerAnimated release];
	[onDismissModalViewControllerAnimated release];
	[super dealloc];

}

@end
