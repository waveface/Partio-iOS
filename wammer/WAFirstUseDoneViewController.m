//
//  WAFirstUseDoneViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseDoneViewController.h"
#import "WAFirstUseViewController.h"
#import "WARemoteInterface.h"
#import "WADefines.h"
#import "WADefines+iOS.h"
#import "WAAppDelegate_iOS.h"
#import "WASyncManager.h"

@interface WAFirstUseDoneViewController ()

@end

@implementation WAFirstUseDoneViewController

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  [self localize];
  
  self.doneButton.backgroundColor = [UIColor colorWithRed:0x7c/255.0 green:0x9c/255.0 blue:0x35/255.0 alpha:1.0];
  self.doneButton.contentEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
  self.doneButton.layer.cornerRadius = 20.0;
  [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
  [self.doneButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
  
  __weak WAFirstUseDoneViewController *wSelf = self;
  self.navigationItem.leftBarButtonItem = (UIBarButtonItem *)WABackBarButtonItem([UIImage imageNamed:@"back"], @"", ^{
    [wSelf.navigationController popViewControllerAnimated:YES];
  });
  
}

- (void)localize {
  
  self.title = NSLocalizedString(@"SETUP_DONE_CONTROLLER_TITLE", @"Title of view controller finishing first setup");
  
}


@end
