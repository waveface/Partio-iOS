//
//  WAAuthenticationRequestViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/30/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAAuthenticationRequestViewController : UITableViewController

+ (WAAuthenticationRequestViewController *) controllerWithCompletion:(void(^)(WAAuthenticationRequestViewController *self))aBlock;

@property (nonatomic, readwrite, retain) UITextField *usernameField;
@property (nonatomic, readwrite, retain) UITextField *passwordField;

@end
