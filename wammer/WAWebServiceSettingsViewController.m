//
//  WAWebServiceSettingsViewController.m
//  wammer
//
//  Created by kchiu on 12/11/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAWebServiceSettingsViewController.h"
#import "WAFacebookConnectionSwitch.h"
#import "WAOAuthViewController.h"
#import "WAGoogleConnectSwitch.h"

static NSString * const kWASegueSettingsToOAuth = @"WASegueSettingsToOAuth";

@interface WAWebServiceSettingsViewController ()

@property (nonatomic, strong) NSURLRequest *sentRequest;
@property (nonatomic, strong) WAOAuthDidComplete didCompleteBlock;

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

	WAGoogleConnectSwitch *googleOAuthSwitch = [[WAGoogleConnectSwitch alloc] init];
	googleOAuthSwitch.delegate = self;
	self.googleConnectCell.accessoryView = googleOAuthSwitch;

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	WAOAuthViewController *vc = [segue destinationViewController];
	vc.request = self.sentRequest;
	vc.didCompleteBlock = self.didCompleteBlock;

}

#pragma mark - WAOAuthSwitch delegates

- (void)openOAuthWebViewWithRequest:(NSURLRequest *)request completeBlock:(WAOAuthDidComplete)didCompleteBlock {

	self.sentRequest = request;
	self.didCompleteBlock = didCompleteBlock;

	[self performSegueWithIdentifier:kWASegueSettingsToOAuth sender:nil];

}

#pragma mark - UITableView delegates

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

	NSString *headerTitleID = [super tableView:tableView titleForHeaderInSection:section];
	return NSLocalizedString(headerTitleID, @"Header title of web service setting view controller");

}

@end
