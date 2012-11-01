//
//  WAFirstUseSignUpView.m
//  wammer
//
//  Created by kchiu on 12/10/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseSignUpView.h"

@implementation WAFirstUseSignUpView

- (BOOL) isPopulated {
	
	return [self.emailField.text length] && [self.passwordField.text length] && [self.nicknameField.text length];
	
}

@end
