//
//  WASignUpViewController.h
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^WASignUpViewControllerCallback)(NSString *userToken, NSDictionary *userRep, NSArray *groupReps, NSError *error);


@interface WASignUpViewController : UITableViewController

+ (WASignUpViewController *) controllerWithCompletion:(WASignUpViewControllerCallback)block;

- (IBAction) handleDone:(id)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneItem;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *nicknameField;

@end
