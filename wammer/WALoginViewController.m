//
//  WALogInViewController.m
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALogInViewController.h"
#import "WARemoteInterface.h"

@interface WALogInViewController () <UITextFieldDelegate>

+ (UIStoryboard *) storyboard;
@property (nonatomic, readwrite, copy) WALogInViewControllerCallback callback;

- (BOOL) isPopulated;

@end


@implementation WALogInViewController
@synthesize doneItem = _doneItem;
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

- (void) viewDidLoad {

	[super viewDidLoad];
	
	UIView *bgView = [[UIView alloc] initWithFrame:CGRectZero];
	bgView.backgroundColor = [UIColor colorWithRed:203.0f/255.0f green:227.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
	
	self.tableView.backgroundView = bgView;
	self.doneItem.enabled = [self isPopulated];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:NO animated:animated];

}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

	self.doneItem.enabled = [self isPopulated];

	return YES;

}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {

	if (!textField.text.length)
		return NO;
	
	if (textField == _emailField) {
		
		[_passwordField becomeFirstResponder];
		
	} else if (textField == _passwordField) {
	
		if ([self isPopulated])
			[self handleDone:nil];
	
	}
	
	return YES;

}

- (BOOL) isPopulated {

	return [self.emailField.text length] && [self.passwordField.text length];

}

- (IBAction) handleDone:(id)sender {

	[_emailField resignFirstResponder];
	[_passwordField resignFirstResponder];

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
