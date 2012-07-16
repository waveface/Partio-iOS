//
//  WALogInViewController.m
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALogInViewController.h"
#import "WARemoteInterface.h"

@interface WALogInViewController ()

+ (UIStoryboard *) storyboard;
@property (nonatomic, readwrite, copy) WALogInViewControllerCallback callback;

@end


@implementation WALogInViewController
@synthesize emailField = _emailField;
@synthesize passwordField = _passwordField;
@synthesize callback = _callback;

+ (UIStoryboard *) storyboard {

	return [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];

}

+ (WALogInViewController *) controllerWithCompletion:(WALogInViewControllerCallback)block {

	WALogInViewController *controller = (WALogInViewController *)[[self storyboard] instantiateInitialViewController];
	NSCParameterAssert([controller isKindOfClass:[WALogInViewController class]]);
	
	controller.callback = block;
	
	return controller;

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:NO animated:animated];

}

- (IBAction) handleDone:(id)sender {

	NSString *userName = self.emailField.text;
	NSString *password = self.passwordField.text;
	
	[[WARemoteInterface sharedInterface] retrieveTokenForUser:userName password:password onSuccess:^(NSDictionary *userRep, NSString *token,NSArray *groupReps) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (self.callback)
				self.callback(token, userRep, groupReps, nil);
		
		});
		
	} onFailure:^(NSError *error) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (self.callback)
				self.callback(nil, nil, nil, error);
		
		});

	}];
	
}

@end
