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

}

- (IBAction)handleDone:(id)sender {

	WAFirstUseViewController *firstUseVC = (WAFirstUseViewController *)self.navigationController;
	if (firstUseVC.didFinishBlock) {
		firstUseVC.didFinishBlock();
	}

}

@end
