//
//  WAFBRequestViewController.m
//  wammer
//
//  Created by Shen Steven on 5/21/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFBRequestViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@interface WAFBRequestViewController ()
@property (nonatomic, weak) IBOutlet UIButton *confirmButton;
@property (nonatomic, weak) IBOutlet UIView *bottomView;

@end

@implementation WAFBRequestViewController

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
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [self.confirmButton setBackgroundColor:[UIColor colorWithRed:0.23 green:0.349 blue:0.596 alpha:1]];
  self.confirmButton.layer.cornerRadius = 15;
  
  self.bottomView.layer.cornerRadius = 10;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)confirmButtonClicked:(id)sender {
  __weak WAFBRequestViewController *wSelf = self;
  [[FBSession activeSession] requestNewPublishPermissions:@[@"publish_stream"]
                                          defaultAudience:FBSessionDefaultAudienceFriends
                                        completionHandler:^(FBSession *session, NSError *error) {
    
                                          if (wSelf.completionHandler) {
                                            [wSelf dismissViewControllerAnimated:YES completion:^{

                                              wSelf.completionHandler();
                                              
                                            }];
                                          }
                                          
                                        }];
}

- (IBAction)cancelButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}


@end
