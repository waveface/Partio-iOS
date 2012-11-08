//
//  WAFirstUsePhotoImportViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUsePhotoImportViewController.h"
#import "WADefines.h"

@interface WAFirstUsePhotoImportViewController ()

@end

@implementation WAFirstUsePhotoImportViewController

static BOOL selected = NO;

- (void)viewDidLoad {

	[super viewDidLoad];

	[self localize];

	if (!self.isFromConnectServicesPage) {
		self.navigationItem.hidesBackButton = YES;
	}
	self.navigationItem.rightBarButtonItem.enabled = NO;

	if (selected) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
			self.enablePhotoImportCell.accessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			self.disablePhotoImportCell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}

}

- (void)localize {

	self.title = NSLocalizedString(@"PHOTO_UPLOAD_CONTROLLER_TITLE", @"Title of view controller setting photo upload");

}

#pragma mark UITableView delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *hitCell = [tableView cellForRowAtIndexPath:indexPath];

	self.enablePhotoImportCell.accessoryType = UITableViewCellAccessoryNone;
	self.disablePhotoImportCell.accessoryType = UITableViewCellAccessoryNone;

	hitCell.accessoryType = UITableViewCellAccessoryCheckmark;

	if (hitCell == self.enablePhotoImportCell) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAPhotoImportEnabled];
	} else if (hitCell == self.disablePhotoImportCell) {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAPhotoImportEnabled];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];

	self.navigationItem.rightBarButtonItem.enabled = YES;
	selected = YES;

	[tableView deselectRowAtIndexPath:indexPath animated:YES];

}

@end
