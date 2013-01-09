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
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
    [syncManager addObserver:self forKeyPath:@"importedFilesCount" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
  } else {
    self.photoUploadCell.detailTextLabel.text = NSLocalizedString(@"PHOTO_UPLOAD_STATUS_NOT_UPLOADING", @"Subtitle of photo upload status");
  }
  
  [[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"networkState" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
  
  __weak WAFirstUseDoneViewController *wSelf = self;
  self.navigationItem.leftBarButtonItem = (UIBarButtonItem *)WABackBarButtonItem([UIImage imageNamed:@"back"], @"", ^{
    [wSelf.navigationController popViewControllerAnimated:YES];
  });
  
}

- (void)localize {
  
  self.title = NSLocalizedString(@"SETUP_DONE_CONTROLLER_TITLE", @"Title of view controller finishing first setup");
  
}

- (void)dealloc {
  
  [[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"networkState"];
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    [[(WAAppDelegate_iOS *)AppDelegate() syncManager] removeObserver:self forKeyPath:@"importedFilesCount"];
  }
  
}

#pragma mark Target actions

- (IBAction)handleDone:(id)sender {
  
  WAFirstUseViewController *firstUseVC = (WAFirstUseViewController *)self.navigationController;
  if (firstUseVC.didFinishBlock) {
    firstUseVC.didFinishBlock();
  }
  
}

#pragma mark NSKeyValueObserving delegates

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  __weak WAFirstUseDoneViewController *wSelf = self;
  
  if ([keyPath isEqualToString:@"networkState"]) {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      WARemoteInterface *ri = [WARemoteInterface sharedInterface];
      if ([ri hasReachableStation]) {
        wSelf.connectionCell.accessoryView = nil;
        wSelf.connectionCell.detailTextLabel.text = [ri.monitoredHosts[0] name];
      } else if ([ri hasReachableCloud]) {
        wSelf.connectionCell.accessoryView = nil;
        wSelf.connectionCell.detailTextLabel.text = NSLocalizedString(@"CLOUD_NAME", @"AOStream Cloud Name");
      } else {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activity startAnimating];
        wSelf.connectionCell.accessoryView = activity;
        wSelf.connectionCell.detailTextLabel.text = NSLocalizedString(@"SEARCHING_NETWORK_SUBTITLE", @"Subtitle of searching network in setup done page.");
      }
    }];
    
  } else if ([keyPath isEqualToString:@"importedFilesCount"]) {
    
    NSUInteger currentCount = [change[NSKeyValueChangeNewKey] unsignedIntegerValue];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
      if (currentCount == syncManager.needingImportFilesCount) {
        wSelf.photoUploadCell.detailTextLabel.text = NSLocalizedString(@"PHOTO_UPLOAD_STATUS_UPLOADING", @"Subtitle of photo upload status");
      } else {
        wSelf.photoUploadCell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PHOTO_UPLOAD_STATUS_IMPORTING", @"Subtitle of photo upload status"), currentCount, syncManager.needingImportFilesCount];
      }
    }];
    
  }
  
}

@end
