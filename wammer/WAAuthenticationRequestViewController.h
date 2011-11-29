//
//  WAAuthenticationRequestViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/30/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

//	Error reasons which can be found within the error sent to the controller’s completion block
extern NSString * kWAAuthenticationRequestUserFailure;

@class WAAuthenticationRequestViewController;
typedef void (^WAAuthenticationRequestViewControllerCallback) (WAAuthenticationRequestViewController *self, NSError *error);

@interface WAAuthenticationRequestViewController : UITableViewController

+ (WAAuthenticationRequestViewController *) controllerWithCompletion:(WAAuthenticationRequestViewControllerCallback)aBlock;

@property (nonatomic, readwrite, retain) NSString *username;
@property (nonatomic, readwrite, retain) NSString *password;
@property (nonatomic, readwrite, assign) CGFloat labelWidth;

@property (nonatomic, readwrite, assign) BOOL performsAuthenticationOnViewDidAppear;

@property (nonatomic, readwrite, retain) NSArray *actions;  //  Use IRAction objects

@end
