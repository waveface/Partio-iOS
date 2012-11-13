//
//  WAFirstUseLogInViewController.h
//  wammer
//
//  Created by kchiu on 12/10/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUseLogInViewController : UITableViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *passwordCell;

@end
