//
//  WAFirstUseDoneViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseDoneViewController.h"
#import "WAFirstUseViewController.h"

@interface WAFirstUseDoneViewController ()

@end

@implementation WAFirstUseDoneViewController

- (void)viewDidLoad {

	[super viewDidLoad];
	self.navigationItem.hidesBackButton = YES;
	self.view.backgroundColor = [UIColor colorWithRed:203.0f/255.0f green:227.0f/255.0f blue:234.0f/255.0f alpha:1.0f];

}

- (IBAction)handleDone:(id)sender {

	WAFirstUseViewController *firstUseVC = (WAFirstUseViewController *)self.navigationController;
	if (firstUseVC.completeBlock) {
		firstUseVC.completeBlock();
	}

}

@end
