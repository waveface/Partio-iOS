//
//  WADataPlanViewController.m
//  wammer
//
//  Created by Shen Steven on 1/23/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WADataPlanViewController.h"

@interface WADataPlanViewController ()

@property (nonatomic, strong) UITableViewCell *freePlanCell;
@property (nonatomic, strong) UITableViewCell *premiumPlanCell;
@property (nonatomic, strong) UITableViewCell *ultimatePlanCell;

@end

@implementation WADataPlanViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  return 3;
  
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if ([indexPath row] == 0) {
	if (!self.freePlanCell) {
	  self.freePlanCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
	  self.freePlanCell.textLabel.text = NSLocalizedString(@"OPTION_FREE_PLAN", @"Free plan option in plans page");
	  self.freePlanCell.detailTextLabel.text = NSLocalizedString(@"FREE_PLAN_DESCRIPTION", @"Free plan details in plans page");
	  self.freePlanCell.accessoryType = UITableViewCellAccessoryCheckmark;
	  [self.view setNeedsUpdateConstraints];
	}
	return self.freePlanCell;
  } else if ([indexPath row] == 1) {
	if (!self.premiumPlanCell) {
	  self.premiumPlanCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
	  self.premiumPlanCell.textLabel.text = NSLocalizedString(@"OPTION_PREMIUM_PLAN", @"Premium plan option in plans page");
	  self.premiumPlanCell.detailTextLabel.text = NSLocalizedString(@"PREMIUM_PLAN_DESCRIPTION", @"Premium plan details in plans page");
	  [self.view setNeedsUpdateConstraints];
	}
	return self.premiumPlanCell;
  } else if ([indexPath row] == 2) {
	if (!self.ultimatePlanCell) {
	  self.ultimatePlanCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
	  self.ultimatePlanCell.textLabel.text = NSLocalizedString(@"OPTION_ULTIMATE_PLAN", @"Ultimate plan option in plans page");
	  self.ultimatePlanCell.detailTextLabel.text = NSLocalizedString(@"ULTIMATE_PLAN_DESCRIPTION", @"Ultimate plan details in plans page");
	  [self.view setNeedsUpdateConstraints];
	}
	return self.ultimatePlanCell;
  }
  
  return nil;
  
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *hitCell = [tableView cellForRowAtIndexPath:indexPath];
  
  self.freePlanCell.accessoryType = UITableViewCellAccessoryNone;
  self.premiumPlanCell.accessoryType = UITableViewCellAccessoryNone;
  self.ultimatePlanCell.accessoryType = UITableViewCellAccessoryNone;
  
  hitCell.accessoryType = UITableViewCellAccessoryCheckmark;
  
  if (hitCell == self.freePlanCell) {
	//		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanFree forKey:kWABusinessPlan];
  } else if (hitCell == self.premiumPlanCell) {
	//		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanPremium forKey:kWABusinessPlan];
  } else if (hitCell == self.ultimatePlanCell) {
	//		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanUltimate forKey:kWABusinessPlan];
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
}

@end
