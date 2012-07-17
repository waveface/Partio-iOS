//
//  WAWelcomeViewController.m
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAWelcomeViewController.h"
#import "WASignUpViewController.h"
#import "WALogInViewController.h"
#import "WAFacebookInterface.h"
#import "WAFacebookInterfaceSubclass.h"
#import "WAFacebook.h"
#import "WARemoteInterface.h"

@interface WAWelcomeViewController ()
@property (nonatomic, readwrite, copy) WAWelcomeViewControllerCallback callback;
@end


@implementation WAWelcomeViewController
@synthesize greenTextureView = _greenTextureView;
@synthesize facebookButton = _facebookButton;
@synthesize loginButton = _loginButton;
@synthesize signUpButton = _signUpButton;
@synthesize callback = _callback;

+ (WAWelcomeViewController *) controllerWithCompletion:(WAWelcomeViewControllerCallback)block {

	WAWelcomeViewController *controller = [self new];
	controller.callback = block;
	
	return controller;

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	UIImageView *textureView = self.greenTextureView;
	textureView.backgroundColor = [UIColor colorWithPatternImage:textureView.image];
	textureView.image = nil;
	
	UIImage * (^stretch)(UIImage *) = ^ (UIImage *image) {
	
		return [image stretchableImageWithLeftCapWidth:5.0f topCapHeight:0.0f];
	
	};

	void (^heckle)(UIButton *, UIControlState) = ^ (UIButton *button, UIControlState state) {
	
		[button setBackgroundImage:stretch([button backgroundImageForState:state]) forState:state];

	};
	
	void (^heckleAll)(UIButton *) = ^ (UIButton * button) {
	
		heckle(button, UIControlStateNormal);
		heckle(button, UIControlStateHighlighted);
		heckle(button, UIControlStateSelected);
		heckle(button, UIControlStateDisabled);
		heckle(button, UIControlStateReserved);
		heckle(button, UIControlStateApplication);
	
	};
	
	heckleAll(self.facebookButton);
	heckleAll(self.loginButton);
	heckleAll(self.signUpButton);

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];

}

- (IBAction) handleFacebookConnect:(id)sender {

	//	?
	
	__weak WAWelcomeViewController *wSelf = self;
	__weak WAFacebookInterface *wFBInterface = [WAFacebookInterface sharedInterface];
	
	[wFBInterface authenticateWithCompletion:^(BOOL didFinish, NSError *error) {
	
		if (!didFinish) {
			if (wSelf.callback) {
				wSelf.callback(nil, nil, nil, error);
			}
			return;
		}
		
		WARemoteInterface * ri = [WARemoteInterface sharedInterface];
		
		[ri signupUserWithFacebookToken:wFBInterface.facebook.accessToken withOptions:nil onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
		
			dispatch_async(dispatch_get_main_queue(), ^{
				
				if (wSelf.callback)
					wSelf.callback(token, userRep, groupReps, error);

			});
			
		} onFailure:^(NSError *error) {
		
			dispatch_async(dispatch_get_main_queue(), ^{

				if (wSelf.callback)
					wSelf.callback(nil, nil, nil, error);
			
			});
			
		}];
		
	}];
	

}

- (IBAction) handleLogin:(id)sender {

	__weak WAWelcomeViewController *wSelf = self;
	
	WALogInViewController *logInVC = [WALogInViewController controllerWithCompletion:^(NSString *token, NSDictionary *userRep, NSArray *groupReps, NSError *error) {
	
		if (wSelf.callback)
			wSelf.callback(token, userRep, groupReps, error);
		
	}];
	
	[self.navigationController pushViewController:logInVC animated:YES];

}

- (IBAction) handleSignUp:(id)sender {

	__weak WAWelcomeViewController *wSelf = self;

	WASignUpViewController *signUpVC = [WASignUpViewController controllerWithCompletion:^(NSString *token, NSDictionary *userRep, NSArray *groupReps, NSError *error) {
	
		if (wSelf.callback)
			wSelf.callback(token, userRep, groupReps, error);
		
	}];
	
	[self.navigationController pushViewController:signUpVC animated:YES];

}
- (void)viewDidUnload {
    [self setGreenTextureView:nil];
    [self setFacebookButton:nil];
    [self setLoginButton:nil];
    [self setSignUpButton:nil];
    [super viewDidUnload];
}
@end
