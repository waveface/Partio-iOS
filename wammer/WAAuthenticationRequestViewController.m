//
//  WAAuthenticationRequestViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/30/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAuthenticationRequestViewController.h"
#import "WARemoteInterface.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WAOverlayBezel.h"

#import "WADefines.h"


@interface WAAuthenticationRequestViewController () <UITextFieldDelegate>

@property (nonatomic, readwrite, retain) UITextField *usernameField;
@property (nonatomic, readwrite, retain) UITextField *passwordField;

@property (nonatomic, readwrite, copy) WAAuthenticationRequestViewControllerCallback completionBlock;

- (void) update;
- (void) authenticate;

@end


@implementation WAAuthenticationRequestViewController
@synthesize labelWidth;
@synthesize usernameField, passwordField;
@synthesize username, password, completionBlock;
@synthesize performsAuthenticationOnViewDidAppear;

+ (WAAuthenticationRequestViewController *) controllerWithCompletion:(WAAuthenticationRequestViewControllerCallback)aBlock {

	WAAuthenticationRequestViewController *returnedVC = [[[self alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	returnedVC.completionBlock = aBlock;
	return returnedVC;

}

- (id) initWithStyle:(UITableViewStyle)style {

	self = [super initWithStyle:style];
	if (!self)
		return nil;
	
	self.labelWidth = 128.0f;
	self.title = @"Welcome";
	
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
  self.usernameField.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	self.passwordField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.passwordField.delegate = self;
	self.passwordField.placeholder = @"Password";
	self.passwordField.text = self.password;
	self.passwordField.font = [UIFont systemFontOfSize:17.0f];
	self.passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.passwordField.returnKeyType = UIReturnKeyGo;
	self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordField.secureTextEntry = YES;
	self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
  self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
		
}

- (void) viewDidUnload {

	self.usernameField = nil;
	self.passwordField = nil;
	
	[super viewDidUnload];
	
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {

	if (textField == self.usernameField) {
		BOOL shouldReturn = ![self.usernameField.text isEqualToString:@""];
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
				[self.passwordField resignFirstResponder];
				[self authenticate];
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
	else
		[self.passwordField becomeFirstResponder];
	
}

- (void) viewDidAppear:(BOOL)animated {

  [super viewDidAppear:animated];
  
  if (self.performsAuthenticationOnViewDidAppear) {
    self.performsAuthenticationOnViewDidAppear = NO;
    [self authenticate];
  }

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 2;
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
		cell.textLabel.text = @"Password";
		cell.accessoryView = self.passwordField;
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

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

	return [NSString stringWithFormat:@"Using Endpoint %@", [[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointURL]];

}





- (void) update {

	self.username = self.usernameField.text;
	self.password = self.passwordField.text;

}

- (void) authenticate {

  [self update];

	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	busyBezel.caption = @"Processing";
	
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
	self.view.userInteractionEnabled = NO;

	[[WARemoteInterface sharedInterface] retrieveTokenForUser:self.username password:self.password onSuccess:^(NSDictionary *userRep, NSString *token) {
		
		[WARemoteInterface sharedInterface].userIdentifier = [userRep objectForKey:@"user_id"];
		[WARemoteInterface sharedInterface].userToken = token;
		
		NSArray *allGroups = [userRep objectForKey:@"groups"];
		if ([allGroups count])
			[WARemoteInterface sharedInterface].primaryGroupIdentifier = [[allGroups objectAtIndex:0] valueForKeyPath:@"group_id"];
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			
			if (self.completionBlock)
				self.completionBlock(self, nil);
			
			self.view.userInteractionEnabled = YES;
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
		});

	} onFailure: ^ (NSError *error) {
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if (self.completionBlock)
				self.completionBlock(self, error);
			
			self.view.userInteractionEnabled = YES;
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
		});
			
	}];		

}

@end
