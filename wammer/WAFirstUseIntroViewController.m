//
//  WAFirstUseIntroViewController.m
//  wammer
//
//  Created by kchiu on 12/10/29.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseIntroViewController.h"
#import "WAFirstUseSignUpView.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Accounts/Accounts.h>
#import "WARemoteInterface.h"
#import "WAFirstUseViewController.h"
#import "WAOverlayBezel.h"


static NSString * const kWASegueIntroToConnectServices = @"WASegueIntroToConnectServices";
static NSString * const kWASegueIntroToPhotoImport = @"WASegueIntroToPhotoImport";

@interface WAFirstUseIntroViewController ()

@property (nonatomic, readwrite, strong) NSArray *pages;
@property (nonatomic, strong) UITableViewCell *emailCell;
@property (nonatomic, strong) UITableViewCell *passwordCell;
@property (nonatomic, strong) UITableViewCell *nicknameCell;
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *nicknameField;
@property (nonatomic, readwrite) BOOL pageControlUsed;
@property (nonatomic, readwrite, strong) WAFirstUseSignUpView *signupView;
@property (nonatomic, readwrite) BOOL isKeyboardShown;

@end

// The pagination effect refers sample codes from PageControl in iOS developer library
// Ref: http://developer.apple.com/library/ios/#samplecode/PageControl/Introduction/Intro.html
@implementation WAFirstUseIntroViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	self.pages = [[UINib nibWithNibName:@"WAFirstUseIntroView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil];
	for (UIView *page in self.pages) {
    [self.scrollView addSubview:page];
	}
	self.scrollView.delegate = self;

	self.pageControl.numberOfPages = [self.pages count];
	self.pageControl.currentPage = 0;

	self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");

	self.signupView = [self.pages lastObject];
	self.signupView.dataSource = self;
	self.signupView.delegate = self;
	[self.signupView.facebookSignupButton addTarget:self action:@selector(handleFacebookSignup:) forControlEvents:UIControlEventTouchUpInside];
	[self.signupView.emailSignupButton addTarget:self action:@selector(handleEmailSignup:) forControlEvents:UIControlEventTouchUpInside];

	if (isPhone()) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
	}

	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundWasTouched:)];
	[self.scrollView addGestureRecognizer:tap];

}

- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	self.navigationController.navigationBar.alpha = 1.0f;

	__weak WAFirstUseIntroViewController *wSelf = self;
	[self.pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		CGRect frame = wSelf.view.frame;
		frame.origin.x = frame.size.width * idx;
		frame.origin.y = 0;
		UIView *view = obj;
		view.frame = frame;
	}];

}

- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

	// Set scrollView's contentSize only works here if auto-layout is enabled
	// Ref: http://stackoverflow.com/questions/12619786/embed-imageview-in-scrollview-with-auto-layout-on-ios-6
	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.pages count], self.scrollView.frame.size.height);

}

- (void)dealloc {

	if (isPhone()) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
	}

}


- (void)updateViewConstraints {
	
	[super updateViewConstraints];
	
	if (self.emailCell && self.emailField) {
		self.emailField.translatesAutoresizingMaskIntoConstraints = NO;
		UITextField *emailField = self.emailField;
		[self.emailCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-110-[emailField]-20-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(emailField)]];
		[self.emailCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[emailField(==40)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(emailField)]];
	}
	
	if (self.passwordCell && self.passwordField) {
		self.passwordField.translatesAutoresizingMaskIntoConstraints = NO;
		UITextField *passwordField	= self.passwordField;
		[self.passwordCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-110-[passwordField]-20-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(passwordField)]];
		[self.passwordCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[passwordField(==40)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(passwordField)]];
	}
	
	if (self.nicknameCell && self.nicknameField) {
		
		self.nicknameField.translatesAutoresizingMaskIntoConstraints = NO;
		UITextField *nicknameField	= self.nicknameField;
		[self.nicknameCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-110-[nicknameField]-20-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(nicknameField)]];
		[self.nicknameCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[nicknameField(==40)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(nicknameField)]];
		
	}
	
}

#pragma mark Target actions

- (IBAction)handleChangePage:(id)sender {

	NSInteger page = self.pageControl.currentPage;
	CGRect frame = self.scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	[self.scrollView scrollRectToVisible:frame animated:YES];

	if (page == [self.pages count]-1) {
		self.title = NSLocalizedString(@"SIGN_UP_CONTROLLER_TITLE", @"Title for view controller signing the user up");
	} else {
		self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");
	}

	self.pageControlUsed = YES;

}

- (void)handleFacebookSignup:(UIButton *)sender {

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
	__weak WAFirstUseIntroViewController *wSelf = self;

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
						[wSelf performSegueWithIdentifier:kWASegueIntroToConnectServices sender:sender];
					} else {
						// user might have registered facebook account to Stream, then go login flow.
						[wSelf performSegueWithIdentifier:kWASegueIntroToPhotoImport sender:sender];
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

- (void)handleEmailSignup:(UIButton *)sender {

	sender.enabled = NO;
	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
	
	[self.emailField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	[self.nicknameField resignFirstResponder];
	
	NSString *userName = self.emailField.text;
	NSString *password = self.passwordField.text;
	NSString *nickname = self.nicknameField.text;
	
	WAFirstUseViewController *firstUseVC = (WAFirstUseViewController *)self.navigationController;
	__weak WAFirstUseIntroViewController *wSelf = self;

	[[WARemoteInterface sharedInterface] registerUser:userName password:password nickname:nickname onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			sender.enabled = YES;
			
			if (firstUseVC.didAuthSuccessBlock) {
				firstUseVC.didAuthSuccessBlock(token, userRep, groupReps);
			}
			
			if ([userRep[@"state"] isEqualToString:@"created"]) {
				[wSelf performSegueWithIdentifier:kWASegueIntroToConnectServices sender:sender];
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

}

- (void)handleKeyboardWasShown:(NSNotification *)aNotification {

	if (self.isKeyboardShown) {
		return;
	}

	CGSize kbSize = [aNotification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
	self.scrollView.contentInset = contentInsets;
	self.scrollView.scrollIndicatorInsets = contentInsets;

	CGRect viewRect = self.view.frame;
	viewRect.size.height -= kbSize.height;
	CGRect emailSignupButtonFrame = self.signupView.emailSignupButton.frame;
	CGPoint emailSignupButtonAbsoluteOrigin = [self.signupView.emailSignupButton convertPoint:emailSignupButtonFrame.origin toView:self.view];
	if (!CGRectContainsPoint(viewRect, emailSignupButtonAbsoluteOrigin)) {
		CGPoint scrollPoint = CGPointMake(0.0, emailSignupButtonAbsoluteOrigin.y+emailSignupButtonFrame.size.height-viewRect.size.height+6.0);
		[self.scrollView setContentOffset:scrollPoint animated:YES];
	}

	self.scrollView.pagingEnabled = NO;
	self.isKeyboardShown = YES;

}

- (void)handleKeyboardWillBeHidden:(NSNotification *)aNotification {

	self.scrollView.contentInset = UIEdgeInsetsZero;
	self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;

	self.scrollView.pagingEnabled = YES;
	self.isKeyboardShown = NO;

}

- (void)handleBackgroundWasTouched:(NSNotification *)aNotification {
	
	[self.emailField resignFirstResponder];
	[self.passwordField resignFirstResponder];
	[self.nicknameField resignFirstResponder];
	
}

#pragma mark UIScrollView delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

	if (self.isKeyboardShown) {
		// disable horizontal scrolling
		[scrollView setContentOffset:CGPointMake(self.view.frame.size.width * ([self.pages count]-1), scrollView.contentOffset.y)];
		return;
	}
	
	if (self.pageControlUsed) {
		return;
	}

	CGFloat pageWidth = self.scrollView.frame.size.width;
	NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	self.pageControl.currentPage = page;

	if (page == [self.pages count]-1) {
		self.title = NSLocalizedString(@"SIGN_UP_CONTROLLER_TITLE", @"Title for view controller signing the user up");
	} else {
		self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");
	}

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

	self.pageControlUsed = NO;

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

	self.pageControlUsed = NO;

}

#pragma mark UITextField delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

	if (!textField.text.length)
		return NO;
	
	if (textField == self.emailField) {
		
		[self.passwordField becomeFirstResponder];
		
	} else if (textField == self.passwordField) {
		
		[self.nicknameField becomeFirstResponder];

	} else if (textField == self.nicknameField) {
		
		if ([self.emailField.text length] && [self.passwordField.text length] && [self.nicknameField.text length]) {
			[self.signupView.emailSignupButton sendActionsForControlEvents:UIControlEventTouchUpInside];
		}
		
	}
	
	return YES;

}

#pragma mark UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 3;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	if ([indexPath row] == 0) {
		if (!self.emailCell) {
			self.emailCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
			self.emailCell.textLabel.text = NSLocalizedString(@"NOUN_USERNAME", @"Email title in signup page");
			self.emailField = [[UITextField alloc] init];
			self.emailField.font = [UIFont systemFontOfSize:17.0];
			self.emailField.placeholder = NSLocalizedString(@"USERNAME_PLACEHOLDER", @"Email placeholder in signup page");
			self.emailField.delegate = self;
			self.emailField.returnKeyType = UIReturnKeyNext;
			self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
			self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
			[self.emailCell.contentView addSubview:self.emailField];
			[self.view setNeedsUpdateConstraints];
		}
		return self.emailCell;
	} else if ([indexPath row] == 1) {
		if (!self.passwordCell) {
			self.passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
			self.passwordCell.textLabel.text = NSLocalizedString(@"NOUN_PASSWORD", @"Password title in signup page");
			self.passwordField = [[UITextField alloc] init];
			self.passwordField.font = [UIFont systemFontOfSize:17.0];
			self.passwordField.secureTextEntry = YES;
			self.passwordField.placeholder = NSLocalizedString(@"PASSWORD_PLACEHOLDER", @"Password placeholder in signup page");
			self.passwordField.delegate = self;
			self.passwordField.returnKeyType = UIReturnKeyNext;
			self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
			self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			self.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
			[self.passwordCell.contentView addSubview:self.passwordField];
			[self.view setNeedsUpdateConstraints];
		}
		return self.passwordCell;
	} else if ([indexPath row] == 2) {
		if (!self.nicknameCell) {
			self.nicknameCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
			self.nicknameCell.textLabel.text = NSLocalizedString(@"NOUN_NICKNAME", @"Nickname title in signup page");
			self.nicknameField = [[UITextField alloc] init];
			self.nicknameField.font = [UIFont systemFontOfSize:17.0];
			self.nicknameField.placeholder = NSLocalizedString(@"NICKNAME_PLACEHOLDER", @"Nickname placeholder in signup page");
			self.nicknameField.delegate = self;
			self.nicknameField.returnKeyType = UIReturnKeyGo;
			self.nicknameField.autocorrectionType = UITextAutocorrectionTypeYes;
			self.nicknameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
			[self.nicknameCell.contentView addSubview:self.nicknameField];
			[self.view setNeedsUpdateConstraints];
		}
		return self.nicknameCell;
	}

	return nil;

}

@end
