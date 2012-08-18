//
//  WASignUpViewController.m
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASignUpViewController.h"
#import "WARemoteInterface.h"
#import "WAOverlayBezel.h"

@interface WASignUpViewController ()
+ (UIStoryboard *) storyboard;
@property (nonatomic, readwrite, copy) WASignUpViewControllerCallback callback;
@property (nonatomic, readwrite, assign) BOOL inProgress;
@end


@implementation WASignUpViewController
@synthesize doneItem = _doneItem;
@synthesize emailField = _emailField;
@synthesize passwordField = _passwordField;
@synthesize nicknameField = _nicknameField;
@synthesize callback = _callback;
@synthesize inProgress = _inProgress;

+ (UIStoryboard *) storyboard {

	return [UIStoryboard storyboardWithName:NSStringFromClass([self class]) bundle:nil];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return isPad();
	
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
	self.inProgress = NO;

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

	if (self.inProgress) {
		return;
	} else {
		self.inProgress = YES;
	}

	[self.emailField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	[self.nicknameField resignFirstResponder];

	NSString *userName = self.emailField.text;
	NSString *password = self.passwordField.text;
	NSString *nickname = self.nicknameField.text;

	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];

	__weak WASignUpViewController *wSelf = self;
	[[WARemoteInterface sharedInterface] registerUser:userName password:password nickname:nickname onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
	
		wSelf.inProgress = NO;

		dispatch_async(dispatch_get_main_queue(), ^{
			
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
			if (self.callback)
				self.callback(token, userRep, groupReps, nil);

		});
		
	} onFailure:^(NSError *error) {
	
		wSelf.inProgress = NO;

		dispatch_async(dispatch_get_main_queue(), ^{
			
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
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
