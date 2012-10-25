//
//  WAUserInfoViewController.h
//  wammer
//
//  Created by Evadne Wu on 12/1/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRTableViewController.h"
#import "WANavigationController.h"

@class UITableViewSection;
@interface WAUserInfoViewController : IRTableViewController

+ (id) controllerWithWrappingNavController:(WANavigationController **)navController;

@property (weak, nonatomic) IBOutlet UITableViewCell *syncTableViewCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *serviceTableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *contactTableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *stationNagCell;

@property (weak, nonatomic) IBOutlet UILabel *lastSyncDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPendingFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfFilesNotOnStationLabel;
@property (weak, nonatomic) IBOutlet UILabel *stationNagLabel;

@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activity;

@property (weak, nonatomic) IBOutlet UISwitch *photoImportSwitch;

- (IBAction)handlePhotoImportSwitchChanged:(id)sender;

@end
