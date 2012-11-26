//
//  WANavigationController.m
//  wammer
//
//  Created by Evadne Wu on 10/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WANavigationController.h"
#import "UIKit+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"


@interface WANavigationController ()
@property (nonatomic, readwrite, assign) BOOL poppingViewController;
@end


@implementation WANavigationController

@synthesize onViewDidLoad;
@synthesize willPushViewControllerAnimated, didPushViewControllerAnimated;
@synthesize onDismissModalViewControllerAnimated;
@synthesize disablesAutomaticKeyboardDismissal;
@synthesize poppingViewController = _poppingViewController;

+ (id) alloc {

	UIViewController *fauxVC = [[UIViewController alloc] init];
	WANavigationController *fauxNavController = [super alloc];
	fauxNavController = [fauxNavController initWithRootViewController:fauxVC];
	
	NSData *fauxNavCData = [NSKeyedArchiver archivedDataWithRootObject:fauxNavController];
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:fauxNavCData];
	[unarchiver setClass:[UINavigationBar class] forClassName:@"UINavigationBar"];

	return [unarchiver decodeObjectForKey:@"root"];
		
}

- (id) initWithRootViewController:(UIViewController *)presentedViewController {

	NSParameterAssert(!presentedViewController.navigationController);

  self = [super initWithRootViewController:presentedViewController];
  if (!self)
    return nil;
  
	if (presentedViewController)
		[self setViewControllers:[NSArray arrayWithObject:presentedViewController]];
	
  return self;

}

- (void) viewDidLoad {

	[super viewDidLoad];
		
	UINavigationBar *navigationBar = (UINavigationBar *)self.navigationBar;
	[navigationBar setClipsToBounds:YES];
	
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

- (UIViewController *) popViewControllerAnimated:(BOOL)animated {

	_poppingViewController = YES;

	UIViewController *viewController = [super popViewControllerAnimated:animated];
	
	_poppingViewController = NO;
	
	return viewController;

}

- (void) dismissModalViewControllerAnimated:(BOOL)animated {

	[super dismissModalViewControllerAnimated:animated];

	if (self.onDismissModalViewControllerAnimated)
		self.onDismissModalViewControllerAnimated(self, animated);

}

- (BOOL) shouldAutorotate {
	
	return [self.topViewController shouldAutorotate];

}

- (NSUInteger) supportedInterfaceOrientations {
	
	return [self.topViewController supportedInterfaceOrientations];
	
}

@end
