//
//  WAFirstUsePhotoImportViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUsePhotoImportViewController.h"
#import "WADefines.h"

// save switch value in global so that the switch status can be kept even the view controller is dismissed
static BOOL enabled = YES;

@interface WAFirstUsePhotoImportViewController ()

@property (nonatomic, strong) UISwitch *photoImportSwitch;

@end

@implementation WAFirstUsePhotoImportViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	[self localize];

	if (!self.isFromConnectServicesPage) {
		self.navigationItem.hidesBackButton = YES;
	}

	self.photoImportSwitch = [[UISwitch alloc] init];
	[self.photoImportSwitch addTarget:self action:@selector(handleSwitchValueChange:) forControlEvents:UIControlEventValueChanged];
	self.photoImportSwitchCell.accessoryView = self.photoImportSwitch;

	[self.photoImportSwitch setOn:enabled animated:NO];

}

- (void)localize {

	self.title = NSLocalizedString(@"PHOTO_UPLOAD_CONTROLLER_TITLE", @"Title of view controller setting photo upload");

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	if (self.photoImportSwitch.on) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAPhotoImportEnabled];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAPhotoImportEnabled];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];

}

#pragma mark Target actions

- (void)handleSwitchValueChange:(UISwitch *)sender {

	enabled = sender.on;

}

@end
