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

	__weak WAFirstUseIntroViewController *wSelf = self;
	[self.pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		CGRect frame = wSelf.view.frame;
		frame.origin.x = frame.size.width * idx;
		frame.origin.y = 0;
		UIView *view = obj;
		view.frame = frame;
		[wSelf.scrollView addSubview:view];
	}];

	self.pageControl.numberOfPages = [self.pages count];
	self.pageControl.currentPage = 0;

	self.title = NSLocalizedString(@"What is Stream?", @"Navigation title on introduction pages");

	self.scrollView.delegate = self;

	self.signupView = [self.pages lastObject];
	self.signupView.emailField.delegate = self;
	self.signupView.passwordField.delegate = self;
	self.signupView.nicknameField.delegate = self;
	[self.signupView.facebookSignupButton addTarget:self action:@selector(handleFacebookSignup:) forControlEvents:UIControlEventTouchUpInside];
	[self.signupView.emailSignupButton addTarget:self action:@selector(handleEmailSignup:) forControlEvents:UIControlEventTouchUpInside];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];

	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundWasTouched:)];
	[self.scrollView addGestureRecognizer:tap];

}

- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	self.navigationController.navigationBar.alpha = 1.0f;

}

- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

	// Set scrollView's contentSize only works here if auto-layout is enabled
	// Ref: http://stackoverflow.com/questions/12619786/embed-imageview-in-scrollview-with-auto-layout-on-ios-6
	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.pages count], self.scrollView.frame.size.height);

}

#pragma mark Target actions

- (IBAction)handleChangePage:(id)sender {

	NSInteger page = self.pageControl.currentPage;
	CGRect frame = self.scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	[self.scrollView scrollRectToVisible:frame animated:YES];

	if (page == [self.pages count]-1) {
		self.title = NSLocalizedString(@"Sign Up", @"Navigation title on sign up page");
	} else {
		self.title = NSLocalizedString(@"What is Stream?", @"Navigation title on introduction pages");
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
	
	[self.signupView.emailField resignFirstResponder];
	[self.signupView.passwordField resignFirstResponder];
	[self.signupView.nicknameField resignFirstResponder];
	
	NSString *userName = self.signupView.emailField.text;
	NSString *password = self.signupView.passwordField.text;
	NSString *nickname = self.signupView.nicknameField.text;
	
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

	CGSize kbSize = [aNotification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
	self.scrollView.contentInset = contentInsets;
	self.scrollView.scrollIndicatorInsets = contentInsets;

	CGRect viewRect = self.view.frame;
	viewRect.size.height -= kbSize.height;
	CGRect emailSignupButtonFrame = self.signupView.emailSignupButton.frame;
	if (!CGRectContainsPoint(viewRect, emailSignupButtonFrame.origin)) {
		CGPoint scrollPoint = CGPointMake(0.0, emailSignupButtonFrame.origin.y+emailSignupButtonFrame.size.height-viewRect.size.height);
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
	
	[self.signupView.emailField resignFirstResponder];
	[self.signupView.passwordField resignFirstResponder];
	[self.signupView.nicknameField resignFirstResponder];
	
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
		self.title = NSLocalizedString(@"Sign Up", @"Navigation title on sign up page");
	} else {
		self.title = NSLocalizedString(@"What is Stream?", @"Navigation title on introduction pages");
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
	
	if (textField == self.signupView.emailField) {
		
		[self.signupView.passwordField becomeFirstResponder];
		
	} else if (textField == self.signupView.passwordField) {
		
		[self.signupView.nicknameField becomeFirstResponder];
		
	} else if (textField == self.signupView.nicknameField) {
		
		if ([self.signupView isPopulated]) {
			[self.signupView.emailSignupButton sendActionsForControlEvents:UIControlEventTouchUpInside];
		}
		
	}
	
	return YES;

}

@end
