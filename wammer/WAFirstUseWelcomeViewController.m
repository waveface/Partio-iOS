//
//  WAFirstUseAppLaunchViewController.m
//  wammer
//
//  Created by kchiu on 12/10/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseWelcomeViewController.h"

@interface WAFirstUseWelcomeViewController ()

@end

@implementation WAFirstUseWelcomeViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	self.signupButton.backgroundColor = [UIColor colorWithRed:0xe6/255.0 green:0xe6/255.0 blue:0xe6/255.0 alpha:1.0];
	self.signupButton.contentEdgeInsets = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
	self.signupButton.layer.cornerRadius = 10.0;
	self.loginButton.backgroundColor = [UIColor colorWithRed:0xe6/255.0 green:0xe6/255.0 blue:0xe6/255.0 alpha:1.0];
	self.loginButton.contentEdgeInsets = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
	self.loginButton.layer.cornerRadius = 10.0;
	
}

- (void)viewWillAppear:(BOOL)animated {

	self.navigationController.navigationBar.alpha = 0;

}

@end
