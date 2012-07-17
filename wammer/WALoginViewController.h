//
//  WALogInViewController.h
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^WALogInViewControllerCallback)(NSString *token, NSDictionary *userRep, NSArray *groupReps, NSError *error);


@interface WALogInViewController : UITableViewController

+ (WALogInViewController *) controllerWithCompletion:(WALogInViewControllerCallback)block;

- (IBAction) handleDone:(id)sender;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneItem;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end
