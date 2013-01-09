//
//  WAFirstUseBuildCloudViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseBuildCloudViewController.h"
#import "WARemoteInterface.h"

@interface WAFirstUseBuildCloudViewController ()

@end

@implementation WAFirstUseBuildCloudViewController

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  [self localize];
  
  [[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"networkState" options:NSKeyValueObservingOptionInitial context:nil];
  
}

- (void)dealloc {
  
  [[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"networkState"];
  
}

- (void)localize {
  
  self.title = NSLocalizedString(@"STORAGE_SETUP_CONTROLLER_TITLE", @"Title of view controller setting personal cloud");
  
}

#pragma mark NSKeyValueObserving delegates

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  NSParameterAssert([keyPath isEqualToString:@"networkState"]);
  
  WARemoteInterface *ri = [WARemoteInterface sharedInterface];
  if ([ri hasReachableStation]) {
    self.connectionCell.accessoryView = nil;
    self.connectionCell.detailTextLabel.text = [ri.monitoredHosts[0] name];
    self.connectionCell.detailTextLabel.hidden = NO;
  } else if ([ri hasReachableCloud]) {
    self.connectionCell.accessoryView = nil;
    self.connectionCell.detailTextLabel.text = NSLocalizedString(@"CLOUD_NAME", @"AOStream Cloud Name");
    self.connectionCell.detailTextLabel.hidden = NO;
  } else {
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activity startAnimating];
    self.connectionCell.accessoryView = activity;
    self.connectionCell.detailTextLabel.hidden = YES;
  }
  
}

@end
