//
//  WAFirstUseCoachmarkController.m
//  wammer
//
//  Created by Shen Steven on 2/28/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFirstUseCoachmarkController.h"
#import "WAFirstUseViewController.h"

@interface WAFirstUseCoachmarkController ()

@property (nonatomic, strong) IBOutlet UIButton *coachmarkButton;

@end

@implementation WAFirstUseCoachmarkController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.navigationController setNavigationBarHidden:YES];
  CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
  
  if ([UIScreen mainScreen].scale == 2.f && screenHeight == 568.0f) {
    [self.coachmarkButton setBackgroundImage:[UIImage imageNamed:@"coachmark-568h"] forState:UIControlStateNormal];
  } else {
    [self.coachmarkButton setBackgroundImage:[UIImage imageNamed:@"coachmark"] forState:UIControlStateNormal];
  }
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Target actions

- (IBAction)handleDone:(id)sender {
  
  WAFirstUseViewController *firstUseVC = (WAFirstUseViewController *)self.navigationController;
  if (firstUseVC.didFinishBlock) {
    firstUseVC.didFinishBlock();
  }
  
}

@end
