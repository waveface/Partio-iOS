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
@synthesize doneItem = _doneItem;
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

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
		return nil;
	
	return self;

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	UIView *bgView = [[UIView alloc] initWithFrame:CGRectZero];
	bgView.backgroundColor = [UIColor colorWithRed:203.0f/255.0f green:227.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
	
	self.tableView.backgroundView = bgView;
	self.doneItem.enabled = [self isPopulated];
	self.title = NSLocalizedString(@"SIGN_UP_CONTROLLER_TITLE", @"Title for view controller signing the user up");

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
	
		[_nicknameField becomeFirstResponder];
	
	} else if (textField == _nicknameField) {
	
		if ([self isPopulated])
			[self handleDone:nil];
	
	}
	
	return YES;

}

- (BOOL) isPopulated {

	return [self.emailField.text length] && [self.passwordField.text length] && [self.nicknameField.text length];

}

- (IBAction) handleDone:(id)sender {

	[self.emailField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	[self.nicknameField resignFirstResponder];

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

- (void)viewDidUnload {
	[self setDoneItem:nil];
	[super viewDidUnload];
}
@end
