//
//  WARegisterRequestViewController.h
//  wammer
//
//  Created by Evadne Wu on 11/10/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

//	Error reasons which can be found within the error sent to the controller’s completion block
extern NSString * kWARegisterRequestUserFailure;

@class WARegisterRequestViewController;
typedef void (^WARegisterRequestViewControllerCallback) (WARegisterRequestViewController *self, NSError *error);

@interface WARegisterRequestViewController : UITableViewController

+ (WARegisterRequestViewController *) controllerWithCompletion:(WARegisterRequestViewControllerCallback)aBlock;

@property (nonatomic, readonly, copy) NSString *username;
@property (nonatomic, readonly, copy) NSString *userID;
@property (nonatomic, readonly, copy) NSString *nickname;
@property (nonatomic, readonly, copy) NSString *password;
@property (nonatomic, readonly, copy) NSString *token;
@property (nonatomic, readonly, assign) CGFloat labelWidth;

@property (nonatomic, readonly, copy) WARegisterRequestViewControllerCallback completionBlock;

- (void) presentError:(NSError *)error completion:(void(^)(void))block;

@end
