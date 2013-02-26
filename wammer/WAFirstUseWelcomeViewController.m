//
//  WAFirstUseAppLaunchViewController.m
//  wammer
//
//  Created by kchiu on 12/10/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseWelcomeViewController.h"

@interface WAFirstUseWelcomeViewController ()

@end

@implementation WAFirstUseWelcomeViewController

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  UIImage *backgroundPattern = [UIImage imageNamed:@"WelcomeBackgroundPattern"];
  self.tableView.backgroundColor = [UIColor colorWithPatternImage:backgroundPattern];

}

- (void)viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];

  self.navigationController.navigationBar.alpha = 0;
  
}

#pragma mark - UITableViewController delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

@end
