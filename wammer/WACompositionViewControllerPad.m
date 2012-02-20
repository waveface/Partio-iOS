//
//  WACompositionViewControllerPad.m
//  wammer
//
//  Created by Evadne Wu on 2/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACompositionViewControllerPad.h"
#import "UIKit+IRAdditions.h"

@interface WACompositionViewControllerPad ()

@end

@implementation WACompositionViewControllerPad

- (void) presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated {

	if (!animated || (modalViewController.modalTransitionStyle != UIModalTransitionStyleCoverVertical)) {
		[super presentModalViewController:modalViewController animated:animated];
		return;
	}
	
	__block __typeof__(self) nrSelf = self;
	
	void (^dismissalAnimation)() = ^ {

		CATransition *pushTransition = [CATransition animation];
		pushTransition.type = kCATransitionMoveIn;
		pushTransition.duration = 0.3;
		pushTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		pushTransition.subtype = ((NSString * []){
			[UIInterfaceOrientationPortrait] = kCATransitionFromTop,
			[UIInterfaceOrientationPortraitUpsideDown] = kCATransitionFromBottom,
			[UIInterfaceOrientationLandscapeLeft] = kCATransitionFromRight,
			[UIInterfaceOrientationLandscapeRight] = kCATransitionFromLeft
		})[[UIApplication sharedApplication].statusBarOrientation];
					
    [[UIApplication sharedApplication] irBeginIgnoringStatusBarAppearanceRequests];
          
		[nrSelf presentModalViewController:modalViewController animated:NO];
		
		[[UIApplication sharedApplication].keyWindow.layer addAnimation:pushTransition forKey:kCATransition];
		
	};
			
	UIView *firstResponder = [nrSelf.view irFirstResponderInView];

	if (firstResponder) {
	
		[firstResponder resignFirstResponder];
		double delayInSeconds = 0.15;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), dismissalAnimation);
		
	} else {
	
		dismissalAnimation();
		
	}

}

- (void) dismissModalViewControllerAnimated:(BOOL)animated {

	if (!animated || !self.modalViewController || (self.modalViewController.modalTransitionStyle != UIModalTransitionStyleCoverVertical)) {
		[super dismissModalViewControllerAnimated:animated];
		return;
	}
  
	__block __typeof__(self) nrSelf = self;
	
  [CATransaction begin];
  
  CATransition *popTransition = [CATransition animation];
	popTransition.type = kCATransitionReveal;
	popTransition.duration = 0.3;
	popTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	popTransition.subtype = ((NSString * []){
		[UIInterfaceOrientationPortrait] = kCATransitionFromBottom,
		[UIInterfaceOrientationPortraitUpsideDown] = kCATransitionFromTop,
		[UIInterfaceOrientationLandscapeLeft] = kCATransitionFromLeft,
		[UIInterfaceOrientationLandscapeRight] = kCATransitionFromRight,
	})[[UIApplication sharedApplication].statusBarOrientation];
	
	[nrSelf dismissModalViewControllerAnimated:NO];
  
  [[UIApplication sharedApplication] irEndIgnoringStatusBarAppearanceRequests];

  ((^{
    [UIView setAnimationsEnabled:NO];
    NSObject *viewControllerClass = (NSObject *)[UIViewController class];
    if ([viewControllerClass respondsToSelector:@selector(attemptRotationToDeviceOrientation)]) {
      [viewControllerClass performSelector:@selector(attemptRotationToDeviceOrientation)];
    }
    [UIView setAnimationsEnabled:YES];
  })());

	[[UIApplication sharedApplication].keyWindow.layer addAnimation:popTransition forKey:kCATransition];
  
  [CATransaction commit];
    
}

@end
