//
//  WAFirstUseChoosePlanViewController.h
//  wammer
//
//  Created by kchiu on 12/10/31.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUseChoosePlanViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITableViewCell *freePlanCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *premiumPlanCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *ultimatePlanCell;

@end
