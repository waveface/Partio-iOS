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
#import "WADefines.h"

#import "WARegisterRequestWebViewController.h"


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

  Class usedClass;
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAUserRegistrationUsesWebVersion])
    usedClass = [WARegisterRequestWebViewController class]; 
  else
    usedClass = self;

	WARegisterRequestViewController *returnedVC = [(WARegisterRequestViewController *)[usedClass alloc] initWithStyle:UITableViewStyleGrouped];
	returnedVC.completionBlock = aBlock;
	return returnedVC;

}

- (id) initWithStyle:(UITableViewStyle)style {

	self = [super initWithStyle:style];
	if (!self)
		return nil;
	
	self.labelWidth = 128.0f;
	self.title = NSLocalizedString(@"REGISTER_REQUEST_TITLE", @"Title for registration request view");
	
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

- (void) viewDidLoad {

	[super viewDidLoad];
	self.usernameField = [[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }];
	self.usernameField.delegate = self;
	self.usernameField.placeholder = NSLocalizedString(@"NOUN_USERNAME", @"Title for username");
	self.usernameField.text = self.username;
	self.usernameField.font = [UIFont systemFontOfSize:17.0f];
	self.usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.usernameField.returnKeyType = UIReturnKeyNext;
	self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.usernameField.keyboardType = UIKeyboardTypeEmailAddress;
  self.usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;

	self.nicknameField = [[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }];
	self.nicknameField.delegate = self;
	self.nicknameField.placeholder = NSLocalizedString(@"NOUN_NICKNAME", @"Title for nick name");
	self.nicknameField.text = self.nickname;
	self.nicknameField.font = [UIFont systemFontOfSize:17.0f];
	self.nicknameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.nicknameField.returnKeyType = UIReturnKeyNext;
	self.nicknameField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.nicknameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.nicknameField.keyboardType = UIKeyboardTypeASCIICapable;
  self.nicknameField.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	self.passwordField = [[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }];
	self.passwordField.delegate = self;
	self.passwordField.placeholder = NSLocalizedString(@"NOUN_PASSWORD", @"Title for password");
	self.passwordField.text = self.password;
	self.passwordField.font = [UIFont systemFontOfSize:17.0f];
	self.passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.passwordField.returnKeyType = UIReturnKeyNext;
	self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordField.secureTextEntry = YES;
	self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
  self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	self.passwordConfirmationField = [[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }];
	self.passwordConfirmationField.delegate = self;
	self.passwordConfirmationField.placeholder = NSLocalizedString(@"NOUN_PASSWORD_CONFIRMATION", @"Title for password confirmation");
	self.passwordConfirmationField.text = nil;//self.password;
	self.passwordConfirmationField.font = [UIFont systemFontOfSize:17.0f];
	self.passwordConfirmationField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.passwordConfirmationField.returnKeyType = UIReturnKeyGo;
	self.passwordConfirmationField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordConfirmationField.secureTextEntry = YES;
	self.passwordConfirmationField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.passwordConfirmationField.keyboardType = UIKeyboardTypeASCIICapable;
  self.passwordConfirmationField.clearButtonMode = UITextFieldViewModeWhileEditing;
		
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
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}

	if (indexPath.row == 0) {
		cell.textLabel.text = NSLocalizedString(@"NOUN_USERNAME", @"Title for username");
		cell.accessoryView = self.usernameField;
	} else if (indexPath.row == 1) {
		cell.textLabel.text = NSLocalizedString(@"NOUN_NICKNAME", @"Title for nickname");
		cell.accessoryView = self.nicknameField;
	} else if (indexPath.row == 2) {
		cell.textLabel.text = NSLocalizedString(@"NOUN_PASSWORD", @"Title for password");
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





- (void) setUsername:(NSString *)newUsername {

  if (username == newUsername)
    return;
  
  username = newUsername;
  
  self.usernameField.text = username;

}

- (void) setPassword:(NSString *)newPassword {

  if (password == newPassword)
    return;
  
  password = newPassword;
  
  self.passwordField.text = password;

}

- (void) setNickname:(NSString *)newNickname {

  if (nickname == newNickname)
    return;
  
  nickname = newNickname;
  
  self.nicknameField.text = nickname;

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

  [self update];

	if (!self.username)
		return;
		
	if (!self.nickname)
		return;
	
	if (!self.password)
		return;

	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	busyBezel.caption = NSLocalizedString(@"ACTION_PROCESSING", @"Action title for processing stuff");
	
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
