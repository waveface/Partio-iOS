//
//  WAImportSettingsViewController.m
//  wammer
//
//  Created by kchiu on 12/11/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAImportSettingsViewController.h"
#import "WADefines.h"
#import "WAFacebookConnectionSwitch.h"

@interface WAImportSettingsViewController ()

@property (nonatomic, strong) UISwitch *photoImportSwitch;

- (void)handlePhotoImportSwitchChanged:(id)sender;


@end

@implementation WAImportSettingsViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	self.title = NSLocalizedString(@"PHOTO_IMPORT_TITLE", @"Title of photo import settings view controller");

	self.photoImportSwitch = [[UISwitch alloc] init];
	[self.photoImportSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]];
	[self.photoImportSwitch addTarget:self action:@selector(handlePhotoImportSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	self.photoImportCell.accessoryView = self.photoImportSwitch;

}

- (void)didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];

}

#pragma mark - Target actions

- (void)handlePhotoImportSwitchChanged:(id)sender {

	UISwitch *photoImportSwitch = sender;
	if ([photoImportSwitch isOn]) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAPhotoImportEnabled];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAPhotoImportEnabled];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];

}

@end
