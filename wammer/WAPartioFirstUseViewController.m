//
//  WAPartioWelcomViewController.m
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioFirstUseViewController.h"

@interface WAPartioFirstUseViewController ()

@end

@implementation WAPartioFirstUseViewController
+ (WAPartioFirstUseViewController*) firstUseViewControllerWithCompletionBlock:(void(^)(BOOL signupSuccess))completion failure:(void(^)(NSError*))failure {

  UIStoryboard *sb = [UIStoryboard storyboardWithName:@"WAPartioFirstUse" bundle:nil];
  WAPartioFirstUseViewController *vc = [sb instantiateInitialViewController];
  vc.completionBlock = completion;
  vc.failureBlock = failure;
  vc.navigationBar.opaque = NO;
  
  return vc;
}

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
@end
