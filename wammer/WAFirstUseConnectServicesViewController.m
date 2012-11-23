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

static NSString * const kWASegueConnectServicesToPhotoImport = @"WASegueConnectServicesToPhotoImport";

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

	__weak WAFirstUseConnectServicesViewController *wSelf = self;
	UIImage *backImage = [UIImage imageNamed:@"back"];
	UIGraphicsBeginImageContext(backImage.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGAffineTransform flippedHorizontal = CGAffineTransformMake(-1, 0, 0, 1, backImage.size.width, 0);
	CGContextConcatCTM(context, flippedHorizontal);
	[backImage drawAtPoint:CGPointZero];
	UIImage *flippedBackImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIBarButtonItem *nextButton = (UIBarButtonItem *)WABackBarButtonItem(flippedBackImage, @"", ^{
		[wSelf performSegueWithIdentifier:kWASegueConnectServicesToPhotoImport sender:nil];
	});

	self.navigationItem.rightBarButtonItem = nextButton;

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	WAFirstUsePhotoImportViewController *vc = segue.destinationViewController;
	vc.isFromConnectServicesPage = YES;

}

- (void)localize {

	self.title = NSLocalizedString(@"CONNECT_SERVICES_CONTROLLER_TITLE", @"Title of view controller connecting services");

}

@end
