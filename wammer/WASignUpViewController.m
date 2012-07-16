//
//  WASignUpViewController.m
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASignUpViewController.h"
#import "WARemoteInterface.h"

@interface WASignUpViewController ()
+ (UIStoryboard *) storyboard;
@property (nonatomic, readwrite, copy) WASignUpViewControllerCallback callback;
@end


@implementation WASignUpViewController
@synthesize emailField = _emailField;
@synthesize passwordField = _passwordField;
@synthesize nicknameField = _nicknameField;
@synthesize callback = _callback;

+ (UIStoryboard *) storyboard {

	return [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];

}

+ (WASignUpViewController *) controllerWithCompletion:(WASignUpViewControllerCallback)block {

	WASignUpViewController *controller = (WASignUpViewController *)[[self storyboard] instantiateInitialViewController];
	NSCParameterAssert([controller isKindOfClass:[WASignUpViewController class]]);
	
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
	NSString *nickname = self.nicknameField.text;
	
	[[WARemoteInterface sharedInterface] registerUser:userName password:password nickname:nickname onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
	
		//	do something with token
		
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
