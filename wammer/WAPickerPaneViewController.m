//
//  WAPickerPaneViewController.m
//  wammer
//
//  Created by Evadne Wu on 4/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPickerPaneViewController.h"

@interface WAPickerPaneViewController ()

@end

@implementation WAPickerPaneViewController

@synthesize backdropView;
@synthesize containerView;

- (void) didMoveToParentViewController:(UIViewController *)parent {

	[super didMoveToParentViewController:parent];
	
	[self runPresentingAnimationWithCompletion:nil];

}

- (void) runPresentingAnimationWithCompletion:(void(^)(void))block {

	CGRect containerToRect = self.containerView.frame;
	CGRect containerFromRect = CGRectOffset(containerToRect, 0, CGRectGetHeight(containerToRect));

	self.backdropView.alpha = 0;
	self.containerView.frame = containerFromRect;
	
	[UIView animateWithDuration:0.3 animations:^{

		self.backdropView.alpha = 1;
		self.containerView.frame = containerToRect;
		
	} completion:^(BOOL finished) {
		
		if (block)
			block();
		
	}];

}

- (void) runDismissingAnimationWithCompletion:(void(^)(void))block {

	CGRect containerFromRect = self.containerView.frame;
	CGRect containerToRect = CGRectOffset(containerFromRect, 0, CGRectGetHeight(containerFromRect));
	
	self.backdropView.alpha = 1;
	self.containerView.frame = containerFromRect;
	
	[UIView animateWithDuration:0.3 animations:^{

		self.backdropView.alpha = 0;
		self.containerView.frame = containerToRect;
		
	} completion:^(BOOL finished) {
		
		if (block)
			block();
		
	}];

}

- (void) viewDidUnload {
	
	[self setBackdropView:nil];
	[self setContainerView:nil];
	
	[super viewDidUnload];

}

- (IBAction) handleCancel:(UIBarButtonItem *)sender {

	//	?
	
}

- (IBAction) handleDone:(UIBarButtonItem *)sender {

	//	?

}

@end
