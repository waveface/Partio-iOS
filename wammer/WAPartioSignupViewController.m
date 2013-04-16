//
//  WAPartioSignupViewController.m
//  wammer
//
//  Created by Shen Steven on 4/16/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioSignupViewController.h"
#import "WAFacebookLoginViewController.h"

@interface WAPartioSignupViewController ()
@property (nonatomic, weak) IBOutlet UIButton *facebookButton;
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
  [self.facebookButton setBackgroundColor:[UIColor blueColor]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)fbButtonClicked:(id)sender {
  
  [WAFacebookLoginViewController backgroundLoginWithFacebookIDWithCompleteHandler:^(NSError *error) {
    if (self.completeHandler)
      self.completeHandler(error);
  }];
  
}

- (IBAction)cancelButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}


@end
