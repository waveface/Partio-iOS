//
//  WAUserDetailViewController.h
//  wammer
//
//  Created by Shen Steven on 1/25/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAUserDetailViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UITableViewCell *userNameTableCell;
@property (nonatomic, weak) IBOutlet UITextField *userNameTextField;
@property (nonatomic, weak) IBOutlet UITableViewCell *userEmailTableCell;
@property (nonatomic, weak) IBOutlet UITextField *userEmailTextField;
@property (nonatomic, weak) IBOutlet UITableViewCell *accountDeleteionTableCell;

@end
