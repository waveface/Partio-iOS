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
#import "WAAppearance.h"
#import "WAGoogleConnectSwitch.h"
#import "WAOAuthViewController.h"

static NSString * const kWASegueConnectServicesToPhotoImport = @"WASegueConnectServicesToPhotoImport";
static NSString * const kWASegueConnectServicesToOAuth = @"WASegueConnectServicesToOAuth";

@interface WAFirstUseConnectServicesViewController ()

@property (nonatomic, strong) NSURLRequest *sentRequest;
@property (nonatomic, strong) WAOAuthDidComplete didCompleteBlock;

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

	WAGoogleConnectSwitch *googleConnectSwitch = [[WAGoogleConnectSwitch alloc] init];
	googleConnectSwitch.delegate = self;
	self.googleConnectCell.accessoryView = googleConnectSwitch;
	
	__weak WAFirstUseConnectServicesViewController *wSelf = self;
	UIBarButtonItem *nextButton = (UIBarButtonItem *)WABackBarButtonItem([UIImage imageNamed:@"forward"], @"", ^{
		[wSelf performSegueWithIdentifier:kWASegueConnectServicesToPhotoImport sender:nil];
	});

	self.navigationItem.rightBarButtonItem = nextButton;

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	if ([segue.identifier isEqualToString:kWASegueConnectServicesToPhotoImport]) {
		WAFirstUsePhotoImportViewController *vc = segue.destinationViewController;
		vc.isFromConnectServicesPage = YES;
	} else if ([segue.identifier isEqualToString:kWASegueConnectServicesToOAuth]) {
		WAOAuthViewController *vc = segue.destinationViewController;
		vc.request = self.sentRequest;
		vc.didCompleteBlock = self.didCompleteBlock;
	}

}

- (void)localize {

	self.title = NSLocalizedString(@"CONNECT_SERVICES_CONTROLLER_TITLE", @"Title of view controller connecting services");

}

#pragma mark - WAOAuthSwitch delegates

- (void)openOAuthWebViewWithRequest:(NSURLRequest *)request completeBlock:(WAOAuthDidComplete)didCompleteBlock {
	
	self.sentRequest = request;
	self.didCompleteBlock = didCompleteBlock;
	
	[self performSegueWithIdentifier:kWASegueConnectServicesToOAuth sender:nil];
	
}

@end
