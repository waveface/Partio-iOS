//
//  WAPartioWelcomeViewController.m
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioWelcomeViewController.h"
#import "WAPartioFirstUseViewController.h"
#import "UIKit+IRAdditions.h"

@interface WAPartioWelcomeViewController ()

@end

@implementation WAPartioWelcomeViewController

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

}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  WAPartioFirstUseViewController *firstUse = (WAPartioFirstUseViewController*)self.navigationController;
  
  if (indexPath.row == 0) {
    IRAction *cancelAction = [IRAction actionWithTitle:@"OK" block:nil];
    
    [[IRAlertView alertViewWithTitle:@"Not support yet"
                             message:@"Current version requires you to login with Facebook account first. 'Try' scenario will be implemented in the near future."
                        cancelAction:cancelAction
                        otherActions:nil] show];

//    if (firstUse.completionBlock)
//      firstUse.completionBlock();
  } 
}

@end
