//
//  WAStationDiscoveryFeedbackViewController.m
//  wammer
//
//  Created by Evadne Wu on 11/30/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "IRAction.h"
#import "IRBarButtonItem.h"

#import "WAStationDiscoveryFeedbackViewController.h"
#import "WANavigationController.h"


@implementation WAStationDiscoveryFeedbackViewController
@synthesize interfaceLabels, dismissalAction;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

  if (!self)
    return nil;
  
  return self;
  
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

  return YES;

}

- (UINavigationController *) wrappingNavigationController {

  WANavigationController *returnedNavC = [[WANavigationController alloc] initWithRootViewController:self];
  
  switch ([UIDevice currentDevice].userInterfaceIdiom) {
    case UIUserInterfaceIdiomPad: { 
      returnedNavC.modalPresentationStyle = UIModalPresentationFormSheet;
      break;
    }
    case UIUserInterfaceIdiomPhone: {
      returnedNavC.modalPresentationStyle = UIModalPresentationFullScreen;
      break;
    }
  };
  
  returnedNavC.onViewDidLoad = ^ (WANavigationController *self) {
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
  };
  
  if ([returnedNavC isViewLoaded])
    returnedNavC.onViewDidLoad(returnedNavC);
  
  return returnedNavC;

}

- (void) viewDidLoad {

  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor clearColor];
  
  if (self.dismissalAction) {
    __weak WAStationDiscoveryFeedbackViewController *wSelf = self;
    self.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithTitle:self.dismissalAction.title action:^{
      [wSelf.dismissalAction invoke];
    }];
  }
  
  for (UILabel *aLabel in self.interfaceLabels) {
    aLabel.textColor = [UIColor whiteColor];
    aLabel.text = NSLocalizedString(aLabel.text, @"Localized");
    aLabel.layer.shadowOpacity = 0.5f;
    aLabel.layer.shadowOffset = (CGSize){ 0, 2 };
  }

}

- (void) viewDidUnload {

  self.interfaceLabels = nil;

  [super viewDidUnload];
  
}

@end
