//
//  WAFirstUseSignUpViewController.m
//  wammer
//
//  Created by kchiu on 12/11/8.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseSignUpViewController.h"
#import "WAFirstUseViewController.h"
#import "WAFirstUseFacebookLoginView.h"
#import "WAFirstUseEmailLoginFooterView.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Accounts/Accounts.h>
#import "WARemoteInterface.h"
#import "WAOverlayBezel.h"
#import "WAAppearance.h"
#import "WADefines.h"

static NSString * const kWASegueSignUpToConnectServices = @"WASegueSignUpToConnectServices";
static NSString * const kWASegueSignUpToPhotoImport = @"WASegueSignUpToPhotoImport";

@interface WAFirstUseSignUpViewController ()

@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *nicknameField;
@property (nonatomic, strong) UIButton *facebookSignupButton;
@property (nonatomic, strong) UIButton *emailSignupButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic) BOOL isKeyboardShown;

@end

@implementation WAFirstUseSignUpViewController

- (void)viewDidLoad {

	[super viewDidLoad];
	
	[self localize];

	self.emailField = [[UITextField alloc] init];
	self.emailField.font = [UIFont systemFontOfSize:17.0];
	self.emailField.placeholder = NSLocalizedString(@"USERNAME_PLACEHOLDER", @"Email placeholder in signup page");
	self.emailField.delegate = self;
	self.emailField.returnKeyType = UIReturnKeyNext;
	self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
	self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
	[self.emailCell.contentView addSubview:self.emailField];

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

	self.nicknameField = [[UITextField alloc] init];
	self.nicknameField.font = [UIFont systemFontOfSize:17.0];
	self.nicknameField.placeholder = NSLocalizedString(@"NICKNAME_PLACEHOLDER", @"Nickname placeholder in signup page");
	self.nicknameField.delegate = self;
	self.nicknameField.returnKeyType = UIReturnKeyGo;
	self.nicknameField.autocorrectionType = UITextAutocorrectionTypeYes;
	self.nicknameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	[self.nicknameCell.contentView addSubview:self.nicknameField];

  WAFirstUseFacebookLoginView *header = [WAFirstUseFacebookLoginView viewFromNib];
	self.tableView.tableHeaderView = header;
	self.facebookSignupButton = header.facebookLoginButton;
	[self.facebookSignupButton addTarget:self action:@selector(handleFacebookSignup:) forControlEvents:UIControlEventTouchUpInside];
	
	WAFirstUseEmailLoginFooterView *footer = [WAFirstUseEmailLoginFooterView viewFromNib];
	self.tableView.tableFooterView = footer;
	self.emailSignupButton = footer.emailLoginButton;
	[self.emailSignupButton setTitle:NSLocalizedString(@"ACTION_SIGN_UP", @"Email sign up button") forState:UIControlStateNormal];
	[self.emailSignupButton setTitle:NSLocalizedString(@"ACTION_SIGN_UP", @"Email sign up button") forState:UIControlStateDisabled];
	[self.emailSignupButton setTitle:NSLocalizedString(@"ACTION_SIGN_UP", @"Email sign up button") forState:UIControlStateHighlighted];
	[self.emailSignupButton addTarget:self action:@selector(handleEmailSignup:) forControlEvents:UIControlEventTouchUpInside];
  [footer.forgotPasswordButton setHidden:YES];

	UIButton *signup = self.emailSignupButton;
	UIButton *facebook = self.facebookSignupButton;
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[signup(==facebook)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(signup, facebook)]];

	self.scrollView = self.tableView;

	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundWasTouched:)];
	[self.scrollView addGestureRecognizer:tap];
	
	if (isPhone()) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
	}

	__weak WAFirstUseSignUpViewController *wSelf = self;
	self.navigationItem.leftBarButtonItem = (UIBarButtonItem *)WABackBarButtonItem([UIImage imageNamed:@"back"], @"", ^{
		[wSelf.navigationController popViewControllerAnimated:YES];
	});

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
		
	self.nicknameField.translatesAutoresizingMaskIntoConstraints = NO;
	UITextField *nicknameField	= self.nicknameField;
	[self.nicknameCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-110-[nicknameField]-20-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(nicknameField)]];
	[self.nicknameCell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[nicknameField(==40)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(nicknameField)]];
	
}

- (void)localize {

	self.title = NSLocalizedString(@"SIGN_UP_CONTROLLER_TITLE", @"Title of view controller signing the user up");

}

- (void)dealloc {
	
	if (isPhone()) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
	}
	
}

#pragma mark Taget actions

- (void)handleFacebookSignup:(UIButton *)sender {
	
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
	__weak WAFirstUseSignUpViewController *wSelf = self;
	
	[FBSession
	 openActiveSessionWithReadPermissions:@[@"email", @"user_photos", @"user_videos", @"user_notes", @"user_status", @"user_likes", @"read_stream", @"friends_photos", @"friends_videos", @"friends_status", @"friends_notes", @"friends_likes"]
	 allowLoginUI:YES
	 completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
		 
       if (error) {
         NSLog(@"Facebook auth error: %@", error);
         return;
       }
       
       BOOL (^snsEnabled)(NSArray*, NSString *) = ^(NSArray *reps, NSString *snsType) {
         NSArray *snsReps = [reps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^ (id evaluatedObject, NSDictionary *bindings) {
           
           return [[evaluatedObject valueForKeyPath:@"type"] isEqual:snsType];
           
         }]];
         
         NSDictionary *snsRep = [snsReps lastObject];
         NSNumber *enabled = [snsRep valueForKeyPath:@"enabled"];
         
         if ([enabled isEqual:(id)kCFBooleanTrue])
           return YES;
         else
           return NO;
       };

		 
       [[WARemoteInterface sharedInterface]
        signupUserWithFacebookToken:session.accessToken
        withOptions:nil
        onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
				
          if (firstUseVC.didAuthSuccessBlock) {
            firstUseVC.didAuthSuccessBlock(token, userRep, groupReps);
          }

          void (^dismissAndContinue)() = ^() {
            dispatch_async(dispatch_get_main_queue(), ^{
              
              [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
              sender.enabled = YES;
              
              if ([userRep[@"state"] isEqualToString:@"created"]) {
                [wSelf performSegueWithIdentifier:kWASegueSignUpToConnectServices sender:sender];
              } else {
                // user might have registered facebook account to Stream, then go login flow.
                [wSelf performSegueWithIdentifier:kWASegueSignUpToPhotoImport sender:sender];
              }
            });
          };
          
          [[WARemoteInterface sharedInterface] retrieveConnectedSocialNetworksOnSuccess:^(NSArray *snsReps) {
            
            BOOL fbImported = snsEnabled(snsReps, @"facebook");
            if (fbImported)
              [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWASNSFacebookConnectEnabled];
            else
              [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWASNSFacebookConnectEnabled];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            dismissAndContinue();
            
          } onFailure:^(NSError *error) {
            // it doesn't matter, just continue the signup flow
            dismissAndContinue();
          }];
          
          
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
	__weak WAFirstUseSignUpViewController *wSelf = self;
	
	[[WARemoteInterface sharedInterface] registerUser:userName password:password nickname:nickname onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			sender.enabled = YES;
			
			if (firstUseVC.didAuthSuccessBlock) {
				firstUseVC.didAuthSuccessBlock(token, userRep, groupReps);
			}
			
			if ([userRep[@"state"] isEqualToString:@"created"]) {
				[wSelf performSegueWithIdentifier:kWASegueSignUpToConnectServices sender:sender];
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
	CGRect emailSignupButtonFrame = self.emailSignupButton.frame;
	CGPoint emailSignupButtonAbsoluteOrigin = [self.emailSignupButton convertPoint:emailSignupButtonFrame.origin toView:self.view];
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
			[self.emailSignupButton sendActionsForControlEvents:UIControlEventTouchUpInside];
		}
		
	}
	
	return YES;
	
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	if ([self.emailField.text length] && [self.passwordField.text length] && [self.nicknameField.text length]) {
		self.emailSignupButton.enabled = YES;
	} else {
		self.emailSignupButton.enabled = NO;
	}
	
	return YES;
	
}

@end
