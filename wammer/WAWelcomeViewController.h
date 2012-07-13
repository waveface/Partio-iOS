//
//  WAWelcomeViewController.h
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^WAWelcomeViewControllerCallback)(NSString *token, NSDictionary *userRep, NSArray *groupReps, NSError *error);


@interface WAWelcomeViewController : UIViewController

+ (WAWelcomeViewController *) controllerWithCompletion:(WAWelcomeViewControllerCallback)block;

- (IBAction) handleFacebookConnect:(id)sender;
- (IBAction) handleLogin:(id)sender;
- (IBAction) handleSignUp:(id)sender;

@end
