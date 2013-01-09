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

@property (weak, nonatomic) IBOutlet UITableViewCell *contactTableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *connectionTableViewCell;
@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *versionCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *logoutCell;

@end
