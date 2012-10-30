//
//  WAFirstUseLogInViewController.h
//  wammer
//
//  Created by kchiu on 12/10/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUseLogInViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

- (IBAction)handleEmailLogin:(id)sender;
- (IBAction)handleFacebookLogin:(id)sender;

@end
