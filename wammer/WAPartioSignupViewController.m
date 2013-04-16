//
//  WAPartioSignupViewController.m
//  wammer
//
//  Created by Shen Steven on 4/9/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioSignupViewController.h"
#import "WAFacebookLoginViewController.h"

@interface WAPartioSignupViewController ()

@property (nonatomic, copy) void (^completionHandler)(NSError *error);

@end

@implementation WAPartioSignupViewController

- (id) initWithCompleteHandler:(void(^)(NSError *error))completeHandler {
  
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    
    self.completionHandler = completeHandler;
    
  }
  return self;
  
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)fbButtonClicked:(id)sender {
 
  [WAFacebookLoginViewController backgroundLoginWithFacebookIDWithCompleteHandler:^(NSError *error) {
    if (self.completionHandler)
      self.completionHandler(error);
  }];

}
@end
