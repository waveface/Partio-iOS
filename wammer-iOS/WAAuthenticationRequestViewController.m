//
//  WAAuthenticationRequestViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/30/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAuthenticationRequestViewController.h"
#import "WARemoteInterface.h"


@interface WAAuthenticationRequestViewController () <UITextFieldDelegate>

@property (nonatomic, readwrite, retain) UITextField *usernameField;
@property (nonatomic, readwrite, retain) UITextField *passwordField;
@property (nonatomic, readwrite, copy) void(^completionBlock)(WAAuthenticationRequestViewController *self);

- (void) authenticate;

@end


@implementation WAAuthenticationRequestViewController
@synthesize labelWidth;
@synthesize usernameField, passwordField, completionBlock;

+ (WAAuthenticationRequestViewController *) controllerWithCompletion:(void(^)(WAAuthenticationRequestViewController *self))aBlock {

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

- (void) viewDidLoad {

	[super viewDidLoad];
	self.usernameField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.usernameField.delegate = self;
	self.usernameField.placeholder = @"Username";
	self.usernameField.font = [UIFont systemFontOfSize:17.0f];
	self.usernameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.usernameField.returnKeyType = UIReturnKeyNext;
	self.usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
	
	self.passwordField = [[[UITextField alloc] initWithFrame:(CGRect){ 0, 0, 256, 44 }] autorelease];
	self.passwordField.delegate = self;
	self.passwordField.placeholder = @"Password";
	self.passwordField.font = [UIFont systemFontOfSize:17.0f];
	self.passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	self.passwordField.returnKeyType = UIReturnKeyDone;
	self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordField.secureTextEntry = YES;
		
}

- (void) viewDidUnload {

	[super viewDidUnload];
	self.usernameField = nil;
	self.passwordField = nil;
	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

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

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	[self.usernameField becomeFirstResponder];
	
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
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





- (void) authenticate {

	self.view.userInteractionEnabled = NO;

	[[WARemoteInterface sharedInterface] retrieveTokenForUserWithIdentifier:self.usernameField.text password:self.passwordField.text onSuccess:^(NSDictionary *userRep, NSString *token) {
		
		[WARemoteInterface sharedInterface].userIdentifier = [userRep objectForKey:@"creator_id"];
		[WARemoteInterface sharedInterface].userToken = token;
		
		//	Hook this up with Keychain services
		
		[[WADataStore defaultStore] updateUsersOnSuccess: ^  {
		
			dispatch_async(dispatch_get_main_queue(), ^ {
				
				if (self.completionBlock)
					self.completionBlock(self);
				
				self.view.userInteractionEnabled = YES;
				
			});
			
		} onFailure: ^ {
		
			dispatch_async(dispatch_get_main_queue(), ^ {
		
				self.view.userInteractionEnabled = YES;
				
				[[[[UIAlertView alloc] initWithTitle:@"Authentication Failure" message:@"Authentication failed.  Unable to retrieve all the users." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
			
			});
			
		}];
		
	} onFailure:^(NSError *error) {
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			self.view.userInteractionEnabled = YES;
		
			[[[[UIAlertView alloc] initWithTitle:@"Authentication Failure" message:[NSString stringWithFormat:@"Authentication failed: %@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
		
		});
			
	}];		

}

@end
