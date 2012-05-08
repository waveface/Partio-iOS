//
//  WAAuthenticationRequestViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/30/11.
//  Copyright 2011 Waveface Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

//	Error reasons which can be found within the error sent to the controller’s completion block
extern NSString * kWAAuthenticationRequestUserFailure;

@class WAAuthenticationRequestViewController, IRAction;
typedef void (^WAAuthenticationRequestViewControllerCallback) (WAAuthenticationRequestViewController *self, NSError *error);

@interface WAAuthenticationRequestViewController : UITableViewController

+ (WAAuthenticationRequestViewController *) controllerWithCompletion:(WAAuthenticationRequestViewControllerCallback)aBlock;
@property (nonatomic, readonly, copy) WAAuthenticationRequestViewControllerCallback completionBlock;

- (void) authenticate;

@property (nonatomic, readwrite, copy) NSString *username;
@property (nonatomic, readwrite, copy) NSString *userID;
@property (nonatomic, readwrite, copy) NSString *password;
@property (nonatomic, readwrite, copy) NSString *token;
@property (nonatomic, readwrite, assign) CGFloat labelWidth;

@property (nonatomic, readwrite, assign) BOOL performsAuthenticationOnViewDidAppear;
- (void) assignFirstResponderStatusToBestMatchingField;

@property (nonatomic, readonly, assign) BOOL validForAuthentication;

@property (nonatomic, readwrite, retain) NSArray *actions;  //  Use IRAction objects
- (IRAction *) newSignInAction;
- (IRAction *) newSignInWithFacebookAction;
- (IRAction *) newRegisterAction;

- (void) presentError:(NSError *)error completion:(void(^)(void))block;

@end
