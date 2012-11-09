//
//  WAFirstUseLogInViewController.m
//  wammer
//
//  Created by kchiu on 12/10/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseLogInViewController.h"
#import "WAFirstUseViewController.h"
#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"
#import "WAFirstUseFacebookLoginView.h"
#import "WAFirstUseEmailLoginFooterView.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Accounts/Accounts.h>


static NSString * const kWASegueLogInToPhotoImport = @"WASegueLogInToPhotoImport";
static NSString * const kWASegueLogInToConnectServices = @"WASegueLogInToConnectServices";

@interface WAFirstUseLogInViewController ()

@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *facebookLoginButton;
@property (nonatomic, strong) UIButton *emailLoginButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic) BOOL isKeyboardShown;

@end

@implementation WAFirstUseLogInViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	[self localize];

	self.emailField = [[UITextField alloc] init];
	self.emailField.font = [UIFont systemFontOfSize:17.0];
	self.emailField.placeholder = NSLocalizedString(@"USERNAME_PLACEHOLDER", @"Email placeholder in login page");
	self.emailField.delegate = self;
	self.emailField.returnKeyType = UIReturnKeyNext;
	self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
	[self.emailCell.contentView addSubview:self.emailField];
	
	self.passwordField = [[UITextField alloc] init];
	self.passwordField.font = [UIFont systemFontOfSize:17.0];
	self.passwordField.secureTextEntry = YES;
	self.passwordField.placeholder = NSLocalizedString(@"PASSWORD_PLACEHOLDER", @"Password placeholder in login page");
	self.passwordField.delegate = self;
	self.passwordField.returnKeyType = UIReturnKeyGo;
	self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
	[self.passwordCell.contentView addSubview:self.passwordField];

  WAFirstUseFacebookLoginView *header = [WAFirstUseFacebookLoginView viewFromNib];
	self.tableView.tableHeaderView = header;
	self.facebookLoginButton = header.facebookLoginButton;
	[self.facebookLoginButton addTarget:self action:@selector(handleFacebookLogin:) forControlEvents:UIControlEventTouchUpInside];

	WAFirstUseEmailLoginFooterView *footer = [WAFirstUseEmailLoginFooterView viewFromNib];
	self.tableView.tableFooterView = footer;
	self.emailLoginButton = footer.emailLoginButton;
	[self.emailLoginButton addTarget:self action:@selector(handleEmailLogin:) forControlEvents:UIControlEventTouchUpInside];

	UIButton *login = self.emailLoginButton;
	UIButton *facebook = self.facebookLoginButton;
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[login(==facebook)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(login, facebook)]];

	self.scrollView = self.tableView;

	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundWasTouched:)];
	[self.scrollView addGestureRecognizer:tap];

	if (isPhone()) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
	}

}

- (void)updateViewConstraints {

	[super updateViewConstraints];

	self.emailField.translatesAutoresizingMaskIntoConstraints = NO;
	UITextField *emailField = self.emailField;
	[self.emailCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-110-[emailField]-20-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(emailField)]];
	[self.emailCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[emailField(==40)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(emailField)]];

	self.passwordField.translatesAutoresizingMaskIntoConstraints = NO;
	UITextField *passwordField	= self.passwordField;
	[self.passwordCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-110-[passwordField]-20-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(passwordField)]];
	[self.passwordCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[passwordField(==40)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(passwordField)]];

}

- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	self.navigationController.navigationBar.alpha = 1.0f;

}

- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height);

}

- (void)dealloc {

	if (isPhone()) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	}

}

- (void)localize {

	self.title = NSLocalizedString(@"SIGN_IN_CONTROLLER_TITLE", @"Title for view controller signing the user in");

}

#pragma mark Target actions

- (void)handleEmailLogin:(UIButton *)sender {

	sender.enabled = NO;
	[self.emailField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	
	NSString *userName = self.emailField.text;
	NSString *password = self.passwordField.text;
	
	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];

	WAFirstUseViewController *firstUseVC = (WAFirstUseViewController *)self.navigationController;
	__weak WAFirstUseLogInViewController *wSelf = self;

	[[WARemoteInterface sharedInterface] retrieveTokenForUser:userName password:password onSuccess:^(NSDictionary *userRep, NSString *token,NSArray *groupReps) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			sender.enabled = YES;
			
			if (firstUseVC.didAuthSuccessBlock) {
				firstUseVC.didAuthSuccessBlock(token, userRep, groupReps);
			}
						
			[wSelf performSegueWithIdentifier:kWASegueLogInToPhotoImport sender:sender];

		});
		
	} onFailure:^(NSError *error) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			sender.enabled = YES;
			
			if (firstUseVC.didAuthFailBlock) {
				firstUseVC.didAuthFailBlock(error);
			}

		});
		
	}];
}

- (void)handleFacebookLogin:(UIButton *)sender {

	// TODO: duplicate function, needs refactoring
	sender.enabled = NO;
	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
	
	// http://stackoverflow.com/questions/12601191/facebook-sdk-3-1-error-validating-access-token
	// This should and will be fixed from FB SDK
	
	ACAccountStore *accountStore;
	ACAccountType *accountTypeFB;
	if ((accountStore = [[ACAccountStore alloc] init]) &&
			(accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook] ) ){
		
    NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
    id account;
    if (fbAccounts && [fbAccounts count] > 0 &&
        (account = [fbAccounts objectAtIndex:0])){
			
			[accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
				//we don't actually need to inspect renewResult or error.
				if (error){
					
				}
			}];
    }
	}
	
	WAFirstUseViewController *firstUseVC = (WAFirstUseViewController *)self.navigationController;
	__weak WAFirstUseLogInViewController *wSelf = self;
	
	[FBSession
	 openActiveSessionWithReadPermissions:@[@"email", @"user_photos", @"user_videos", @"user_notes", @"user_status", @"read_stream"]
	 allowLoginUI:YES
	 completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
		 
		 if (error) {
			 NSLog(@"Facebook auth error: %@", error);
			 return;
		 }
		 
		 [[WARemoteInterface sharedInterface]
			signupUserWithFacebookToken:session.accessToken
			withOptions:nil
			onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
				
				dispatch_async(dispatch_get_main_queue(), ^{
					
					[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
					sender.enabled = YES;
					
					if (firstUseVC.didAuthSuccessBlock) {
						firstUseVC.didAuthSuccessBlock(token, userRep, groupReps);
					}
					
					if ([userRep[@"state"] isEqualToString:@"created"]) {
						// user might haven't registered facebook account to Stream, then go signup flow.
						[wSelf performSegueWithIdentifier:kWASegueLogInToConnectServices sender:sender];
					} else {
						[wSelf performSegueWithIdentifier:kWASegueLogInToPhotoImport sender:sender];
					}
					
				});
				
			} onFailure:^(NSError *error) {
				
				dispatch_async(dispatch_get_main_queue(), ^{
					
					[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
					sender.enabled = YES;
					
					if (firstUseVC.didAuthFailBlock) {
						firstUseVC.didAuthFailBlock(error);
					}
					
				});
				
			}];
		 
	 }];

}

- (void)handleKeyboardWasShown:(NSNotification *)aNotification {
	
	CGSize kbSize = [aNotification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
	self.scrollView.contentInset = contentInsets;
	
	CGRect viewRect = self.view.frame;
	viewRect.size.height -= kbSize.height;
	CGRect emailLoginButtonFrame = self.emailLoginButton.frame;
	CGPoint emailLoginButtonAbsoluteOrigin = [self.emailLoginButton convertPoint:emailLoginButtonFrame.origin toView:self.view];
	if (!CGRectContainsPoint(viewRect, emailLoginButtonAbsoluteOrigin)) {
		CGPoint scrollPoint = CGPointMake(0.0, emailLoginButtonAbsoluteOrigin.y+emailLoginButtonFrame.size.height-viewRect.size.height+15.0);
		[self.scrollView setContentOffset:scrollPoint animated:YES];
	}
	
	self.isKeyboardShown = YES;
	
}

- (void)handleKeyboardWillBeHidden:(NSNotification *)aNotification {
	
	self.scrollView.contentInset = UIEdgeInsetsZero;
	[self.scrollView setContentOffset:CGPointZero animated:YES];
	
	self.isKeyboardShown = NO;
	
}

- (void)handleBackgroundWasTouched:(NSNotification *)aNotification {

	[self.emailField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	
}

#pragma mark UITextField delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	if (!textField.text.length)
		return NO;
	
	if (textField == self.emailField) {
		
		[self.passwordField becomeFirstResponder];
		
	} else if (textField == self.passwordField) {
		
		if ([self.emailField.text length] && [self.passwordField.text length]) {
			[self.emailLoginButton sendActionsForControlEvents:UIControlEventTouchUpInside];
		}
		
	}

	return YES;
	
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

	if ([self.emailField.text length] && [self.passwordField.text length]) {
		self.emailLoginButton.enabled = YES;
	} else {
		self.emailLoginButton.enabled = NO;
	}

	return YES;

}

@end
