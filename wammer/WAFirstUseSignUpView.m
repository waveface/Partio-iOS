//
//  WAFirstUseSignUpView.m
//  wammer
//
//  Created by kchiu on 12/10/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseSignUpView.h"
#import "WAFirstUseFacebookLoginView.h"
#import "WAFirstUseEmailLoginFooterView.h"

@implementation WAFirstUseSignUpView

- (void)awakeFromNib {

	[super awakeFromNib];

	WAFirstUseFacebookLoginView *header = [WAFirstUseFacebookLoginView viewFromNib];
	self.tableHeaderView = header;
	self.facebookSignupButton = header.facebookLoginButton;
	[self.facebookSignupButton setTitle:NSLocalizedString(@"ACTION_CONNECT_FACEBOOK", @"Facebook sign up button") forState:UIControlStateNormal];
	
	WAFirstUseEmailLoginFooterView *footer = [WAFirstUseEmailLoginFooterView viewFromNib];
	self.tableFooterView = footer;
	self.emailSignupButton = footer.emailLoginButton;
	[self.emailSignupButton setTitle:NSLocalizedString(@"ACTION_SIGN_UP", @"Email sign up button") forState:UIControlStateNormal|UIControlStateDisabled];

	UIButton *login = self.emailSignupButton;
	UIButton *facebook = self.facebookSignupButton;
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[login(==facebook)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(login, facebook)]];

}

@end
