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
#import "WADataStore.h"
#import "WARemoteInterface.h"

@interface WAImportSettingsViewController ()

@property (nonatomic, strong) UISwitch *photoImportSwitch;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

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

	UISwitch *backupToPCSwitch = [[UISwitch alloc] init];
	[backupToPCSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kWABackupFilesToPCEnabled]];
	[backupToPCSwitch addTarget:self action:@selector(handleBackupToPCSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	[[WARemoteInterface sharedInterface] irObserve:@"monitoredHosts.@count" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			if ([toValue unsignedIntegerValue] > 1) {
				backupToPCSwitch.enabled = YES;
			} else {
				backupToPCSwitch.enabled = NO;
				backupToPCSwitch.on = NO;
			}
		}];
	}];
	self.backupToPCCell.accessoryView = backupToPCSwitch;

	UISwitch *backupToCloudSwitch = [[UISwitch alloc] init];
	[backupToCloudSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kWABackupFilesToCloudEnabled]];
	[backupToCloudSwitch addTarget:self action:@selector(handleBackupToCloudSwitchChanged:) forControlEvents:UIControlEventValueChanged];
	if ([[NSUserDefaults standardUserDefaults] integerForKey:kWABusinessPlan] == WABusinessPlanFree) {
		backupToCloudSwitch.enabled = NO;
	}
	self.backupToCloudCell.accessoryView = backupToCloudSwitch;

	NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = [NSEntityDescription entityForName:@"WAFile" inManagedObjectContext:context];
	request.predicate = [NSPredicate predicateWithFormat:@"(assetURL != nil OR resourceFilePath != nil) AND resourceURL == nil"];
	request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
	self.fetchedResultsController.delegate = self;

	NSError *error = nil;
	if ([self.fetchedResultsController performFetch:&error]) {
		self.pendingFilesCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [self.fetchedResultsController.fetchedObjects count]];
	} else {
		NSLog(@"Unable to fetch files needing backup, error:%@", error);
	}

}

- (void)didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];

}

- (NSUInteger) supportedInterfaceOrientations {
	
	if (isPad())
		return UIInterfaceOrientationMaskAll;
	else
		return UIInterfaceOrientationMaskPortrait;
	
}

- (BOOL) shouldAutorotate {
	
	return YES;
	
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

	[self.tableView reloadData];

}

- (void)handleBackupToPCSwitchChanged:(id)sender {

	UISwitch *backupToPCSwitch = sender;
	if ([backupToPCSwitch isOn]) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWABackupFilesToPCEnabled];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWABackupFilesToPCEnabled];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];

}

- (void)handleBackupToCloudSwitchChanged:(id)sender {

	UISwitch *backupToCloudSwitch = sender;
	if ([backupToCloudSwitch isOn]) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWABackupFilesToCloudEnabled];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWABackupFilesToCloudEnabled];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];

}

#pragma mark - UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

	if ([self.photoImportSwitch isOn]) {
		// show backup and account upgrade sections
		return 3;
	}

	return 1;

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

	NSString *headerTitleID = [super tableView:tableView titleForHeaderInSection:section];
	
	return NSLocalizedString(headerTitleID, @"Header title of file backup section in photo import settings view controller");

}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

	NSString *footerTitleID = [super tableView:tableView titleForFooterInSection:section];

	return NSLocalizedString(footerTitleID, @"Footer title of file backup section in photo import settings view controller");

	return nil;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *hitCell = [tableView cellForRowAtIndexPath:indexPath];

	if (hitCell == self.upgradeAccountCell) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}

}

#pragma mark - NSFetchedResultsController delegates

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {

	NSParameterAssert([NSThread isMainThread]);
	
	self.pendingFilesCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [controller.fetchedObjects count]];

}

@end
