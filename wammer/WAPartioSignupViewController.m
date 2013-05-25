//
//  WAPartioSignupViewController.m
//  wammer
//
//  Created by Shen Steven on 4/16/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioSignupViewController.h"
#import "WAFBSigninViewController.h"

@interface WAPartioSignupViewController ()
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
@property (nonatomic, weak) IBOutlet UIView *bottomView;
@end

@implementation WAPartioSignupViewController

- (id)initWithCompleteHandler:(void(^)(NSError *error))completeHandler {

  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.completeHandler = completeHandler;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.facebookButton setBackgroundColor:[UIColor colorWithRed:0.23 green:0.349 blue:0.596 alpha:1]];
  self.facebookButton.layer.cornerRadius = 15;
  
  self.bottomView.layer.cornerRadius = 10;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)fbButtonClicked:(id)sender {
  
  [WAFBSigninViewController backgroundLoginWithFacebookIDWithCompleteHandler:^(NSError *error) {
    if (self.completeHandler)
      self.completeHandler(error);
  }];
  
}

- (IBAction)cancelButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}


@end
