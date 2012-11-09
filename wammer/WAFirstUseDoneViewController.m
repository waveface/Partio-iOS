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
		self.photoUploadCell.detailTextLabel.text = NSLocalizedString(@"PHOTO_UPLOAD_STATUS_UPLOADING", @"Subtitle of photo upload status");
	} else {
		self.photoUploadCell.detailTextLabel.text = NSLocalizedString(@"PHOTO_UPLOAD_STATUS_NOT_UPLOADING", @"Subtitle of photo upload status");
	}

	[[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"networkState" options:NSKeyValueObservingOptionInitial context:nil];

}

- (void)localize {

	self.title = NSLocalizedString(@"SETUP_DONE_CONTROLLER_TITLE", @"Title of view controller finishing first setup");

}

- (void)dealloc {
	
	[[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"networkState"];
	
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
	
	NSParameterAssert([keyPath isEqualToString:@"networkState"]);
	
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	if ([ri hasReachableStation]) {
		self.connectionCell.accessoryView = nil;
		self.connectionCell.detailTextLabel.text = ri.monitoredHostNames[1];
	} else if (ri.monitoredHosts && [ri hasReachableCloud]) {
		self.connectionCell.accessoryView = nil;
		self.connectionCell.detailTextLabel.text = ri.monitoredHostNames[0];
	} else {
		UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[activity startAnimating];
		self.connectionCell.accessoryView = activity;
		self.connectionCell.detailTextLabel.text = NSLocalizedString(@"SEARCHING_NETWORK_SUBTITLE", @"Subtitle of searching network in setup done page.");
	}
	
}

@end
