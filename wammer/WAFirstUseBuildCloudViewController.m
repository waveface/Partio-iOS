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
		[self.connectActivity stopAnimating];
		self.connectedHost.text = ri.monitoredHostNames[1];
		self.connectedHost.hidden = NO;
	} else if (ri.monitoredHosts && [ri hasReachableCloud]) {
			[self.connectActivity stopAnimating];
			self.connectedHost.text = ri.monitoredHostNames[0];
			self.connectedHost.hidden = NO;
	} else {
		[self.connectActivity startAnimating];
		self.connectedHost.hidden = YES;
	}

}

@end
