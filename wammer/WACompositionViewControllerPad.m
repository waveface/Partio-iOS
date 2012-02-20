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

@property (nonatomic, readwrite, retain) UIPopoverController *imagePickerPopover;
@property (nonatomic, readwrite, retain) UIButton *imagePickerPopoverPresentingSender;
@property (nonatomic, readwrite, assign) CGRect lastAdjustedInterfaceBounds;

@end


@implementation WACompositionViewControllerPad
@synthesize imagePickerPopover, imagePickerPopoverPresentingSender, lastAdjustedInterfaceBounds;

- (void) adjustContainerViewWithInterfaceBounds:(CGRect)newBounds {

	[super adjustContainerViewWithInterfaceBounds:newBounds];
	
	if (!CGRectEqualToRect(self.lastAdjustedInterfaceBounds, newBounds))
	if ([imagePickerPopover isPopoverVisible]) {
		
		//	[UIView animateWithDuration:5.0 delay:0 options:UIViewAnimationOptionOverrideInheritedCurve|UIViewAnimationOptionOverrideInheritedDuration animations:^{
		//		
		//		[self presentImagePickerController:(IRImagePickerController *)imagePickerPopover.contentViewController sender:self.imagePickerPopoverPresentingSender];
		//		
		//	} completion:nil];
		
	}
	
	self.lastAdjustedInterfaceBounds = newBounds;

}

- (void) presentImagePickerController:(IRImagePickerController *)controller sender:(UIButton *)sender {

	@try {
	
		self.imagePickerPopover.contentViewController = controller;
	
		if (!self.imagePickerPopover)
			self.imagePickerPopover = [[[UIPopoverController alloc] initWithContentViewController:controller] autorelease];
					
		if (!self.imagePickerPopoverPresentingSender)
			self.imagePickerPopoverPresentingSender = sender;
	
		[self.imagePickerPopover presentPopoverFromRect:sender.bounds inView:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:NO];
				
	} @catch (NSException *exception) {

		[[[[UIAlertView alloc] initWithTitle:@"Error Presenting Image Picker" message:@"There was an error presenting the image picker." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
	
	}

}

- (void) dismissImagePickerController:(IRImagePickerController *)controller {

	self.imagePickerPopoverPresentingSender = nil;

	[self.imagePickerPopover dismissPopoverAnimated:YES];

}

- (void) presentCameraCapturePickerController:(IRImagePickerController *)controller sender:(id)sender {

	__block __typeof__(self) nrSelf = self;
	__block __typeof__(controller) nrController = controller;
	
	controller.showsCameraControls = NO;
	controller.onViewDidAppear = ^ (BOOL animated) {
		
//		[nrController retain];
//		
//		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
			
			nrController.showsCameraControls = YES;
      nrController.view.frame = [nrController.view.window convertRect:[nrController.view.window.screen applicationFrame] fromWindow:nil];
//			[nrController autorelease];
//		
//		});
		
	};
	
	void (^animation)() = ^ {

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
          
		[nrSelf presentModalViewController:controller animated:NO];
		
		[[UIApplication sharedApplication].keyWindow.layer addAnimation:pushTransition forKey:kCATransition];
		
	};
			
	UIView *firstResponder = [nrSelf.view irFirstResponderInView];

	if (firstResponder) {
	
		[firstResponder resignFirstResponder];
		double delayInSeconds = 0.15;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), animation);
		
	} else {
	
		animation();
		
	}

}

- (void) dismissCameraCapturePickerController:(IRImagePickerController *)controller {

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
	
	[controller dismissModalViewControllerAnimated:NO];
	
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

- (void) viewDidUnload {

	self.imagePickerPopover = nil;

	[super viewDidUnload];

}

- (void) dealloc {

	[imagePickerPopover release];
	
	[super dealloc];

}

@end
