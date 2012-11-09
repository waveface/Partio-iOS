//
//  WAFirstUseConnectServicesViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseConnectServicesViewController.h"
#import "WAFirstUsePhotoImportViewController.h"
#import "WAFacebookConnectionSwitch.h"

@interface WAFirstUseConnectServicesViewController ()

@end

@implementation WAFirstUseConnectServicesViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	[self localize];

	self.navigationItem.hidesBackButton = YES;

	self.facebookConnectCell.accessoryView = [[WAFacebookConnectionSwitch alloc] init];
	UISwitch *twitterSwitch = [[UISwitch alloc] init];
	twitterSwitch.enabled = NO;
	self.twitterConnectCell.accessoryView = twitterSwitch;
	UISwitch *flickrSwitch = [[UISwitch alloc] init];
	flickrSwitch.enabled = NO;
	self.flickrConnectCell.accessoryView = flickrSwitch;
	UISwitch *picasaSwitch = [[UISwitch alloc] init];
	picasaSwitch.enabled = NO;
	self.picasaConnectCell.accessoryView = picasaSwitch;

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	WAFirstUsePhotoImportViewController *vc = segue.destinationViewController;
	vc.isFromConnectServicesPage = YES;

}

- (void)localize {

	self.title = NSLocalizedString(@"CONNECT_SERVICES_CONTROLLER_TITLE", @"Title of view controller connecting services");

}

@end
