//
//  WALoginViewController.m
//  wammer
//
//  Created by jamie on 6/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALoginViewController.h"

#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"
#import "WAAuthenticationRequestWebViewController.h"
#import "WARegisterRequestViewController.h"
#import "WADefines.h"

#import "IRAction.h"
#import "IRAlertView.h"


@interface WALoginViewController () <UITextFieldDelegate>

- (void)localize:(UIView *) view;

@property (nonatomic) BOOL performsAuthenticationOnViewDidAppear;
@property NSString *username;
@property NSString *password;
@property NSString *userID;
@property NSString *token;

@end

@implementation WALoginViewController
@synthesize usernameField;
@synthesize passwordField;
@synthesize signUpLabel;
@synthesize signUpButton;
@synthesize signInButton;
@synthesize signInWithFacebookButton;
@synthesize username;
@synthesize password;
@synthesize userID;
@synthesize token;
@synthesize completionBlock;
@synthesize performsAuthenticationOnViewDidAppear;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)localize:(UIView *) view {
	for (UIView* v in [view subviews]){
			if([v isKindOfClass:[UILabel class]]){
				UILabel *aLabel = (UILabel *)v;
				aLabel.text = NSLocalizedString(aLabel.text, nil);
			} else if ([v isKindOfClass:[UITextField class]]) {
				UITextField *aField = (UITextField *)v;
				aField.placeholder = NSLocalizedString(aField.placeholder, nil);
			} else if ([v isKindOfClass:[UIButton class]]) {
				UIButton *aButton = (UIButton *)v;
				[aButton setTitle:NSLocalizedString(aButton.titleLabel.text, nil) forState:UIControlStateNormal];
			} else if ([v isKindOfClass:[UIView class]]){
				[self localize:v];
			} else {
				// no op
			}
		}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self localize: self.view];
	// Dress up buttons
	
	[self.signInButton 
		setBackgroundImage:[[UIImage imageNamed:@"SignInButton"] resizableImageWithCapInsets:(UIEdgeInsets){22, 5,22, 5}] 
		forState:UIControlStateNormal];
	[self.signInButton
		setBackgroundImage:[[UIImage imageNamed:@"SignInButtonPressed"] resizableImageWithCapInsets:(UIEdgeInsets){22, 5,22, 5}]
	 forState: UIControlStateHighlighted];
	 
	
	[self.signInWithFacebookButton
		setBackgroundImage:[[UIImage imageNamed:@"SignInWithFacebookButton"] resizableImageWithCapInsets:(UIEdgeInsets){22,5,22,5}] 
		forState:UIControlStateNormal];
	[self.signInWithFacebookButton
		setBackgroundImage:[[UIImage imageNamed:@"SignInWithFacebookButtonPressed"] resizableImageWithCapInsets:(UIEdgeInsets){22,5,22,5}] 
		forState:UIControlStateHighlighted];

	if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ){
	}
	
	self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.45 green:0.71 blue:0.78 alpha:1.0];
}

- (void)viewDidUnload
{
	[self setUsernameField:nil];
	[self setPasswordField:nil];
	[self setSignUpButton:nil];
	[self setSignUpLabel:nil];
	[self setSignInButton:nil];
	[self setSignInWithFacebookButton:nil];

	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	for (UIView* v in [self.view subviews]) 
		if ([v isKindOfClass:[UIButton class]]) {
			UIButton *aButton = (UIButton *)v;
			aButton.titleLabel.text = NSLocalizedString(aButton.titleLabel.text, nil);
			aButton.titleLabel.textAlignment = UITextAlignmentCenter;
			aButton.titleLabel.shadowOffset = (CGSize){0,1};

		}
	self.signUpLabel.textAlignment = UITextAlignmentCenter;
//	self.signUpButton.titleLabel.textColor = self.signUpLabel.textColor;
}

- (void) authenticate {
	
	WF_TESTFLIGHT(^ {
		[TestFlight passCheckpoint:@"SignIn"];	
	});

	if([self.usernameField.text length]) {
		self.username = self.usernameField.text;
		self.password = self.passwordField.text;
	}
  
  if(!([self.username length] || [self.userID length]) && ([self.password length] || [self.token length]))
		return;

//	if (WAAdvancedFeaturesEnabled()) {
//		[[NSUserDefaults standardUserDefaults] setObject:self.username forKey:kWADebugAutologinUserIdentifier];
//		[[NSUserDefaults standardUserDefaults] setObject:self.password forKey:kWADebugAutologinUserPassword];
//		[[NSUserDefaults standardUserDefaults] synchronize];
//	}
  
	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	busyBezel.caption = NSLocalizedString(@"ACTION_PROCESSING", @"Action title for processing stuff");
	
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
	self.view.userInteractionEnabled = NO;
	
	void (^handleAuthSuccess)(NSString *, NSString *, NSString *) = ^ (NSString *inUserID, NSString *inUserToken, NSString *inUserGroupID) {

		[WARemoteInterface sharedInterface].userIdentifier = inUserID;
		[WARemoteInterface sharedInterface].userToken = inUserToken;
		[WARemoteInterface sharedInterface].primaryGroupIdentifier = inUserGroupID;
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			
			if (self.completionBlock)
				self.completionBlock(self, nil);
			
			self.view.userInteractionEnabled = YES;
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
		});
	
	};
	
	void (^handleAuthFailure)(NSError *) = ^ (NSError *error) {

		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if (self.completionBlock)
				self.completionBlock(self, error);
			
			self.view.userInteractionEnabled = YES;
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
		});
	
	};
	
	if ([self.userID length] && ![self.password length] && [self.token length]) {
	
		[WARemoteInterface sharedInterface].userIdentifier = self.userID;
		[WARemoteInterface sharedInterface].userToken = self.token;
		
		[[WARemoteInterface sharedInterface] retrieveUser:self.userID onSuccess:^(NSDictionary *userRep) {
			
			NSArray *allGroups = [userRep objectForKey:@"groups"];
			NSString *groupID = [allGroups count] ? [[allGroups objectAtIndex:0] valueForKey:@"group_id"] : nil;
			
			handleAuthSuccess(self.userID, self.token, groupID);
			
		} onFailure:^(NSError *error) {
			
			handleAuthFailure(error);
			
		}];
	
	} else {
	
		[[WARemoteInterface sharedInterface] retrieveTokenForUser:self.username password:self.password onSuccess:^(NSDictionary *userRep, NSString *inToken) {
		
			NSString *inUserID = [userRep objectForKey:@"user_id"];
			NSArray *allGroups = [userRep objectForKey:@"groups"];
			NSString *groupID = [allGroups count] ? [[allGroups objectAtIndex:0] valueForKey:@"group_id"] : nil;
			
			handleAuthSuccess(inUserID, inToken, groupID);
			
		} onFailure: ^ (NSError *error) {
			
			handleAuthFailure(error);
				
		}];
	
	}

}

- (void) viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
	
	if (self.performsAuthenticationOnViewDidAppear){
		self.performsAuthenticationOnViewDidAppear = NO;
		[self authenticate];
	}
	
}

- (IBAction)signInAction:(id)sender {
	[self authenticate];
}

- (IBAction)facebookSignInAction:(id)sender {
	
	self.usernameField.text = nil;

	__weak WALoginViewController *wSelf = self;
	__weak WAAuthenticationRequestViewController *authRequestVC = [WAAuthenticationRequestWebViewController controllerWithCompletion:^(WAAuthenticationRequestViewController *vc, NSError *error) {
		
			if (error) {
				
				[wSelf presentError:error completion:^{
				
				[wSelf.navigationController popToViewController:wSelf animated:YES];
				}];
				
				return;
				
			}
			
      wSelf.username = vc.username;
      wSelf.password = vc.password;
      wSelf.token = vc.token;
      wSelf.userID = vc.userID;
      wSelf.performsAuthenticationOnViewDidAppear = YES;

      [wSelf.navigationController popToViewController:wSelf animated:YES];
			
		}];
		
		[self.navigationController pushViewController:authRequestVC animated:YES];
		
}

- (IBAction)registerAction:(id)sender {

	self.usernameField.text = nil;

	__weak WALoginViewController *wSelf = self;
	WARegisterRequestViewController *registerRequestVC = [WARegisterRequestViewController controllerWithCompletion:^(WARegisterRequestViewController *vc, NSError *error) {
    
      if (error) {
				
				[vc presentError:error completion:^{
					
					[wSelf.navigationController popToViewController:wSelf animated:YES];
				
				}];
				
				return;
				
      }
			
      wSelf.username = vc.username;
      wSelf.password = vc.password;
      wSelf.token = vc.token;
      wSelf.userID = vc.userID;
      wSelf.performsAuthenticationOnViewDidAppear = YES;

      [wSelf.navigationController popToViewController:wSelf animated:YES];

    }];
  
		[self.navigationController pushViewController:registerRequestVC animated:YES];
}

- (IBAction)swipeAction:(id)sender {
	
	if ( [self.usernameField isFirstResponder] )
		[self.usernameField resignFirstResponder];
	if ( [self.passwordField isFirstResponder] )
		[self.passwordField resignFirstResponder];
		
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

- (void) assignFirstResponderStatusToBestMatchingField {

	if (![self.usernameField.text length]) {
		[self.usernameField becomeFirstResponder];
	} else if (![self.passwordField.text length]) {
		[self.passwordField becomeFirstResponder];
  }

}

- (void) presentError:(NSError *)error completion:(void(^)(void))block {

	__weak WALoginViewController *wSelf = self;

	// check if the error is caused by unreachable cloud
	if (![[WARemoteInterface sharedInterface] hasReachableCloud])
	{
		NSString *alertTitleConnectionFailure = NSLocalizedString(@"ERROR_CONNECTION_FAILED_TITLE", @"Title for connection failure in login view");
		[[IRAlertView alertViewWithTitle:alertTitleConnectionFailure message:NSLocalizedString(@"ERROR_CONNECTION_FAILED_RECOVERY_NOTION", @"Recovery notion for connection failure recovey") cancelAction:nil otherActions:[NSArray arrayWithObjects:[IRAction actionWithTitle:NSLocalizedString(@"ACTION_OKAY", @"OK action in connection failure alert") block:^{
		
			wSelf.password = nil;
			[wSelf assignFirstResponderStatusToBestMatchingField];
			
		}], nil]] show];
		return;
	}
	
	NSString *resetPasswordTitle = NSLocalizedString(@"ACTION_RESET_PASSWORD", @"Action title for resetting password in login view");
	
	IRAction *resetPasswordAction = [IRAction actionWithTitle:resetPasswordTitle block: ^ {
	
		wSelf.password = nil;
		[wSelf assignFirstResponderStatusToBestMatchingField];

		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWAUserPasswordResetEndpointURL]]];
	
  }];

	NSString *alertTitleAuthFailure = NSLocalizedString(@"ERROR_AUTHENTICATION_FAILED_TITLE", @"Title for authentication failure in login view");
	
	[[IRAlertView alertViewWithTitle:alertTitleAuthFailure message:nil cancelAction:[IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Cancel action in login view") block:^{
	
		wSelf.password = nil;
		[wSelf assignFirstResponderStatusToBestMatchingField];
		
	}] otherActions:[NSArray arrayWithObjects:
		
		resetPasswordAction,
		
	nil]]show];

}

@end
