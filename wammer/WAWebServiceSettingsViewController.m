//
//  WAWebServiceSettingsViewController.m
//  wammer
//
//  Created by kchiu on 12/11/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAWebServiceSettingsViewController.h"
#import "WAFacebookConnectionSwitch.h"

@interface WAWebServiceSettingsViewController ()

@end

@implementation WAWebServiceSettingsViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	self.title = NSLocalizedString(@"WEB_SERVICES_TITLE", @"Title of web service settings view controller");

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

- (void)didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];

}

#pragma mark - UITableView delegates

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

	NSString *headerTitleID = [super tableView:tableView titleForHeaderInSection:section];
	return NSLocalizedString(headerTitleID, @"Header title of web service setting view controller");

}

@end
