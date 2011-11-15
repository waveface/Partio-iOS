//
//  WARegisterRequestViewController.m
//  wammer
//
//  Created by Evadne Wu on 11/10/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARegisterRequestViewController.h"
#import "WARemoteInterface.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WAOverlayBezel.h"


@interface WARegisterRequestViewController () <UITextFieldDelegate>

@property (nonatomic, readwrite, retain) UITextField *usernameField;
@property (nonatomic, readwrite, retain) UITextField *nicknameField;
@property (nonatomic, readwrite, retain) UITextField *passwordField;
@property (nonatomic, readwrite, retain) UITextField *passwordConfirmationField;

@property (nonatomic, readwrite, copy) WARegisterRequestViewControllerCallback completionBlock;

- (void) register;
- (void) update;

@end


@implementation WARegisterRequestViewController
@synthesize labelWidth;
@synthesize usernameField, nicknameField, passwordField, passwordConfirmationField;
@synthesize username, nickname, password, completionBlock;

+ (WARegisterRequestViewController *) controllerWithCompletion:(WARegisterRequestViewControllerCallback)aBlock {

	WARegisterRequestViewController *returnedVC = [[[self alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	returnedVC.completionBlock = aBlock;
	return returnedVC;

}

- (id) initWithStyle:(UITableViewStyle)style {

	self = [super initWithStyle:style];
	if (!self)
		return nil;
	
	self.labelWidth = 128.0f;
	self.title = @"Register";
	
	switch (UI_USER_INTERFACE_IDIOM()) {
		
		case UIUserInterfaceIdiomPhone: {
			self.labelWidth = 128.0f;
			break;
		}
		case UIUserInterfaceIdiomPad: {
			self.labelWidth = 192.0f;
			break;
		}
	}
	
	return self;

}

- (void) dealloc {

	[username release];
	[usernameField release];
	
	[password release];
	[passwordField release];
	[passwordConfirmationField release];
	
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	self.usernameField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.usernameField.delegate = self;
	self.usernameField.placeholder = @"Username";
	self.usernameField.text = self.username;
	self.usernameField.font = [UIFont systemFontOfSize:17.0f];
	self.usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.usernameField.returnKeyType = UIReturnKeyNext;
	self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.usernameField.keyboardType = UIKeyboardTypeEmailAddress;
	
	self.nicknameField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.nicknameField.delegate = self;
	self.nicknameField.placeholder = @"Nickname";
	self.nicknameField.text = self.nickname;
	self.nicknameField.font = [UIFont systemFontOfSize:17.0f];
	self.nicknameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.nicknameField.returnKeyType = UIReturnKeyNext;
	self.nicknameField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.nicknameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.nicknameField.keyboardType = UIKeyboardTypeASCIICapable;
	
	self.passwordField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.passwordField.delegate = self;
	self.passwordField.placeholder = @"Password";
	self.passwordField.text = self.password;
	self.passwordField.font = [UIFont systemFontOfSize:17.0f];
	self.passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.passwordField.returnKeyType = UIReturnKeyNext;
	self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordField.secureTextEntry = YES;
	self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
	
	self.passwordConfirmationField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.passwordConfirmationField.delegate = self;
	self.passwordConfirmationField.placeholder = @"Confirm Password";
	self.passwordConfirmationField.text = nil;//self.password;
	self.passwordConfirmationField.font = [UIFont systemFontOfSize:17.0f];
	self.passwordConfirmationField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.passwordConfirmationField.returnKeyType = UIReturnKeyGo;
	self.passwordConfirmationField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordConfirmationField.secureTextEntry = YES;
	self.passwordConfirmationField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.passwordConfirmationField.keyboardType = UIKeyboardTypeASCIICapable;
		
}

- (void) viewDidUnload {

	self.usernameField = nil;
	self.nicknameField = nil;
	self.passwordField = nil;
	self.passwordConfirmationField = nil;
	
	[super viewDidUnload];
	
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {

	if (textField == self.usernameField) {
		BOOL shouldReturn = ![self.usernameField.text isEqualToString:@""];
		if (shouldReturn) {
			dispatch_async(dispatch_get_current_queue(), ^ {
				[self.nicknameField becomeFirstResponder];
			});
		}
		return shouldReturn;
	}
	
	if (textField == self.nicknameField) {
		BOOL shouldReturn = ![self.nicknameField.text isEqualToString:@""];
		if (shouldReturn) {
			dispatch_async(dispatch_get_current_queue(), ^ {
				[self.passwordField becomeFirstResponder];
			});
		}
		return shouldReturn;
	}
		
	if (textField == self.passwordField) {
		BOOL shouldReturn = ![self.passwordField.text isEqualToString:@""];
		if (shouldReturn) {
			dispatch_async(dispatch_get_current_queue(), ^ {
				[self.passwordConfirmationField becomeFirstResponder];
			});
		}
		return shouldReturn;
	}
	
	if (textField == self.passwordConfirmationField) {
		BOOL shouldReturn = ![self.passwordConfirmationField.text isEqualToString:@""];
		if (shouldReturn) {
			dispatch_async(dispatch_get_current_queue(), ^ {
				[self.passwordConfirmationField resignFirstResponder];
				[self register];
			});
		}
		return shouldReturn; 
		
	}
	
	return NO;

}

- (void) textFieldDidEndEditing:(UITextField *)textField {

	[self update];

}

- (void) viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	
	if (!self.usernameField.text)
		[self.usernameField becomeFirstResponder];
	else if (!self.nicknameField.text)
		[self.nicknameField becomeFirstResponder];
	else if (!self.passwordField.text)
		[self.passwordField becomeFirstResponder];
	else
		[self.passwordConfirmationField becomeFirstResponder];
	
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 4;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	if (indexPath.row == 0) {
		cell.textLabel.text = @"Username";
		cell.accessoryView = self.usernameField;
	} else if (indexPath.row == 1) {
		cell.textLabel.text = @"Nickname";
		cell.accessoryView = self.nicknameField;
	} else if (indexPath.row == 2) {
		cell.textLabel.text = @"Password";
		cell.accessoryView = self.passwordField;
	} else if (indexPath.row == 3) {
		cell.textLabel.text = @"";
		cell.accessoryView = self.passwordConfirmationField;
	} else {
		cell.accessoryView = nil;
	}
		
	cell.accessoryView.frame = (CGRect){
		CGPointZero,
		(CGSize){
			CGRectGetWidth(tableView.bounds) - self.labelWidth - ((self.tableView.style == UITableViewStyleGrouped) ? 10.0f : 0.0f),
			45.0f
		}
	};

	return cell;
	
}





- (void) update {

	self.username = self.usernameField.text;
	self.nickname = self.nicknameField.text; 
	
	if ([self.passwordField.text isEqualToString:self.passwordConfirmationField.text])
		self.password = self.passwordField.text;
	else
		self.password = nil;

}

- (void) register {

	if (!self.username)
		return;
		
	if (!self.nickname)
		return;
	
	if (!self.password)
		return;

	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	busyBezel.caption = @"Processing";
	
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
	self.view.userInteractionEnabled = NO;
	
	[[WARemoteInterface sharedInterface] registerUser:self.username password:self.password nickname:self.nickname onSuccess:^(NSDictionary *userRep) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
		
			if (self.completionBlock)
				self.completionBlock(self, nil);

			self.view.userInteractionEnabled = YES;
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
		});
		
	} onFailure:^(NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
		
			if (self.completionBlock)
				self.completionBlock(self, error);
			
			self.view.userInteractionEnabled = YES;
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];

		});
		
	}];

}

@end
