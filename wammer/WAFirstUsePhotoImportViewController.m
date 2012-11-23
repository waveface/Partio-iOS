//
//  WAFirstUsePhotoImportViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUsePhotoImportViewController.h"
#import "WADefines.h"
#import "WAAppearance.h"


// save switch value in global so that the switch status can be kept even the view controller is dismissed
static BOOL enabled = YES;

static NSString * const kWASeguePhotoImportToDone = @"WASeguePhotoImportToDone";

@interface WAFirstUsePhotoImportViewController ()

@property (nonatomic, strong) UISwitch *photoImportSwitch;

@end

@implementation WAFirstUsePhotoImportViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	[self localize];

	self.photoImportSwitch = [[UISwitch alloc] init];
	[self.photoImportSwitch addTarget:self action:@selector(handleSwitchValueChange:) forControlEvents:UIControlEventValueChanged];
	self.photoImportSwitchCell.accessoryView = self.photoImportSwitch;

	[self.photoImportSwitch setOn:enabled animated:NO];

	__weak WAFirstUsePhotoImportViewController *wSelf = self;
	UIImage *backImage = [UIImage imageNamed:@"back"];
	if (!self.isFromConnectServicesPage) {
		self.navigationItem.hidesBackButton = YES;
	} else {
		self.navigationItem.leftBarButtonItem = (UIBarButtonItem *)WABackBarButtonItem(backImage, @"", ^{
			[wSelf.navigationController popViewControllerAnimated:YES];
		});
	}
	
	UIGraphicsBeginImageContext(backImage.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGAffineTransform flippedHorizontal = CGAffineTransformMake(-1, 0, 0, 1, backImage.size.width, 0);
	CGContextConcatCTM(context, flippedHorizontal);
	[backImage drawAtPoint:CGPointZero];
	UIImage *flippedBackImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIBarButtonItem *nextButton = (UIBarButtonItem *)WABackBarButtonItem(flippedBackImage, @"", ^{
		[wSelf performSegueWithIdentifier:kWASeguePhotoImportToDone sender:nil];
	});

	self.navigationItem.rightBarButtonItem = nextButton;

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
