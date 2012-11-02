//
//  WAFirstUseChoosePlanViewController.m
//  wammer
//
//  Created by kchiu on 12/10/31.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseChoosePlanViewController.h"
#import "WADefines.h"

@interface WAFirstUseChoosePlanViewController ()

@end

@implementation WAFirstUseChoosePlanViewController

- (void)viewDidLoad {

	[super viewDidLoad];

}

#pragma mark UITableView delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *hitCell = [tableView cellForRowAtIndexPath:indexPath];

	self.freePlanCell.accessoryType = UITableViewCellAccessoryNone;
	self.premiumPlanCell.accessoryType = UITableViewCellAccessoryNone;
	self.ultimatePlanCell.accessoryType = UITableViewCellAccessoryNone;

	hitCell.accessoryType = UITableViewCellAccessoryCheckmark;

	if (hitCell == self.freePlanCell) {
		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanFree forKey:kWABusinessPlan];
	} else if (hitCell == self.premiumPlanCell) {
		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanPremium forKey:kWABusinessPlan];
	} else if (hitCell == self.ultimatePlanCell) {
		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanUltimate forKey:kWABusinessPlan];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

}

@end
