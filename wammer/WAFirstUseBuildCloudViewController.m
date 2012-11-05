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
	[[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"networkState" options:NSKeyValueObservingOptionInitial context:nil];

}

- (void)dealloc {

	[[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"networkState"];

}

#pragma mark NSKeyValueObserving delegates

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	NSParameterAssert([keyPath isEqualToString:@"networkState"]);

	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	if ([ri hasReachableStation]) {
		self.connectionCell.accessoryView = nil;
		self.connectionCell.detailTextLabel.text = ri.monitoredHostNames[1];
		self.connectionCell.detailTextLabel.hidden = NO;
	} else if (ri.monitoredHosts && [ri hasReachableCloud]) {
		self.connectionCell.accessoryView = nil;
		self.connectionCell.detailTextLabel.text = ri.monitoredHostNames[0];
		self.connectionCell.detailTextLabel.hidden = NO;
	} else {
		UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[activity startAnimating];
		self.connectionCell.accessoryView = activity;
		self.connectionCell.detailTextLabel.hidden = YES;
	}

}

@end
