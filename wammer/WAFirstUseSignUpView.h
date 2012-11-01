//
//  WAFirstUseSignUpView.h
//  wammer
//
//  Created by kchiu on 12/10/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUseSignUpView : UIView

@property (weak, nonatomic) IBOutlet UIButton *facebookSignupButton;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *nicknameField;
@property (weak, nonatomic) IBOutlet UIButton *emailSignupButton;

- (BOOL)isPopulated;

@end
