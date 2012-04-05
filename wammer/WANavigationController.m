//
//  WANavigationController.m
//  wammer
//
//  Created by Evadne Wu on 10/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WANavigationController.h"
#import "WANavigationBar.h"
#import "UIKit+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"


@implementation WANavigationController

@synthesize onViewDidLoad;
@synthesize willPushViewControllerAnimated, didPushViewControllerAnimated;
@synthesize onDismissModalViewControllerAnimated;
@synthesize disablesAutomaticKeyboardDismissal;

+ (id) alloc {

  UIViewController *fauxVC = [[UIViewController alloc] init];
  WANavigationController *fauxNavController = [super alloc];
  fauxNavController = [fauxNavController initWithRootViewController:fauxVC];
  
  NSData *fauxNavCData = [NSKeyedArchiver archivedDataWithRootObject:fauxNavController];
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:fauxNavCData];
  [unarchiver setClass:[WANavigationBar class] forClassName:@"UINavigationBar"];

  return [unarchiver decodeObjectForKey:@"root"];
    
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
	
	WANavigationBar *navigationBar = (WANavigationBar *)self.navigationBar;
	
	if ([navigationBar isKindOfClass:[WANavigationBar class]]) {
		
		navigationBar.customBackgroundView = [WANavigationBar defaultShadowBackgroundView];
		navigationBar.suppressesDefaultAppearance = NO;
		
		__weak WANavigationBar *wNavigationBar = navigationBar;
		
		navigationBar.onBarStyleContextChanged = ^ {
		
			if (wNavigationBar.barStyle == UIBarStyleDefault) {
			
				[wNavigationBar setTintColor:[UIColor colorWithRed:98.0/255.0 green:176.0/255.0 blue:195.0/255.0 alpha:0.0]];
				[wNavigationBar setBackgroundImage:[UIImage imageNamed:@"WANavigationBar"] forBarMetrics:UIBarMetricsDefault];
				[wNavigationBar setBackgroundImage:[UIImage imageNamed:@"WANavigationBarLandscapePhone"] forBarMetrics:UIBarMetricsLandscapePhone];
				
				[wNavigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
					[UIColor colorWithWhite:1 alpha:1], UITextAttributeTextColor,
					[UIColor colorWithWhite:0 alpha:0.5], UITextAttributeTextShadowColor,
					[NSValue valueWithUIOffset:(UIOffset){ 0, -1 }], UITextAttributeTextShadowOffset,
				nil]];
			
			} else {
			
				[wNavigationBar setTintColor:[UIColor blackColor]];
				
				if (wNavigationBar.translucent) {
				
					[wNavigationBar setBackgroundImage:IRUIKitImage(@"UIButtonBarBlackOpaqueBackground") forBarMetrics:UIBarMetricsDefault];
					[wNavigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
				
				} else {
				
					[wNavigationBar setBackgroundImage:IRUIKitImage(@"UIButtonBarBlackTranslucentBackground") forBarMetrics:UIBarMetricsDefault];
					[wNavigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
				
				}
			
			}
			
			[wNavigationBar.layer addAnimation:((^ {
			
				//	This is here to compensate the lack of a smooth fade transition when we re-set the background images
				//	Note: the duration needs to be longer than other implicit bar item transitions happening
				//	otherwise, it’ll get cut off abruptly, which is no good.
			
				CATransition *transition = [CATransition animation];
				transition.type = kCATransitionFade;
				transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
				transition.duration = 0.75;
				
				return transition;
			
			})()) forKey:kCATransition];
			
		};
		
		navigationBar.onBarStyleContextChanged();
		
	}
	
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

	return [super popViewControllerAnimated:animated];

}

- (void) dismissModalViewControllerAnimated:(BOOL)animated {

	[super dismissModalViewControllerAnimated:animated];

	if (self.onDismissModalViewControllerAnimated)
		self.onDismissModalViewControllerAnimated(self, animated);

}

@end
