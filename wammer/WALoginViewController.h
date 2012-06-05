//
//  WALoginViewController.h
//  wammer
//
//  Created by jamie on 6/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

//	Error reasons which can be found within the error sent to the controller’s completion block
extern NSString * kWAAuthenticationRequestUserFailure;

@class WALoginViewController, IRAction;
typedef void (^WALoginViewControllerCallback) (WALoginViewController *self, NSError *error);

@interface WALoginViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UILabel *signUpLabel;
@property (strong, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) IBOutlet UIButton *signInButton;
@property (strong, nonatomic) IBOutlet UIButton *signInWithFacebookButton;

@property (strong, nonatomic)WALoginViewControllerCallback completionBlock;
- (void) presentError:(NSError *)error completion:(void(^)(void))block;

- (IBAction)signInAction:(id)sender;
- (IBAction)facebookSignInAction:(id)sender;
- (IBAction)registerAction:(id)sender;
- (IBAction)swipeAction:(id)sender;

@end
