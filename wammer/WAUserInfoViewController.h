//
//  WAUserInfoViewController.h
//  wammer
//
//  Created by Evadne Wu on 12/1/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRTableViewController.h"

@class UITableViewSection;
@interface WAUserInfoViewController : IRTableViewController

+ (id) controllerWithWrappingNavController:(UINavigationController **)navController;

@property (weak, nonatomic) IBOutlet UITableViewCell *syncTableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *contactTableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *stationNagCell;

@property (weak, nonatomic) IBOutlet UILabel *lastSyncDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPendingFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *numberOfFilesNotOnStationLabel;
@property (weak, nonatomic) IBOutlet UILabel *stationNagLabel;

@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;

@end
