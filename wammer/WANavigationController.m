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
	
	UIColor *naviBgColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
	[navigationBar setTintColor:naviBgColor];
	
	NSValue *shadowOffset = [NSValue valueWithUIOffset:(UIOffset){0,0}];
	
	UIColor *textColor = [UIColor colorWithRed:0.30f green:0.30f blue:0.30f alpha:1];
	[navigationBar setTitleTextAttributes:@{UITextAttributeTextColor: textColor, UITextAttributeTextShadowOffset:shadowOffset}];
	[navigationBar setBarStyle:UIBarStyleDefault];
	
	UIColor *btnTextColor = [UIColor colorWithRed:0.45f green:0.45f blue:0.45f alpha:1];
	[self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{UITextAttributeTextColor: btnTextColor, UITextAttributeTextShadowOffset:shadowOffset} forState:UIControlStateNormal];
	[self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeTextColor: btnTextColor, UITextAttributeTextShadowOffset:shadowOffset} forState:UIControlStateNormal];
	[self.navigationItem.backBarButtonItem setTitleTextAttributes:@{UITextAttributeTextColor: btnTextColor, UITextAttributeTextShadowOffset:shadowOffset} forState:UIControlStateNormal];
	
	[self.navigationItem.leftBarButtonItem setTintColor:naviBgColor];
	[self.navigationItem.rightBarButtonItem setTintColor:naviBgColor];


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

- (NSUInteger) supportedInterfaceOrientations {

	#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
		#define UIInterfaceOrientationMaskLandscapeLeft 16
		#define UIInterfaceOrientationMaskLandscapeRight 8
		#define UIInterfaceOrientationMaskPortrait 2
		#define UIInterfaceOrientationMaskPortraitUpsideDown 4
	#endif

	UIViewController *topVC = self.topViewController;
	
	if (_poppingViewController)
		if ([self.viewControllers count] > 1)
			topVC = [self.viewControllers objectAtIndex:([self.viewControllers count] - 2)];
	
	NSUInteger mask = 0;
	
	if ([topVC shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortrait])
		mask |= UIInterfaceOrientationMaskPortrait;
	
	if ([topVC shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown])
		mask |= UIInterfaceOrientationMaskPortraitUpsideDown;
	
	if ([topVC shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft])
		mask |= UIInterfaceOrientationMaskLandscapeLeft;
	
	if ([topVC shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeRight])
		mask |= UIInterfaceOrientationMaskLandscapeRight;
	
	return mask;

}

@end
