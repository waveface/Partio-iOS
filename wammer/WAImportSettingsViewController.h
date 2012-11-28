//
//  WAImportSettingsViewController.h
//  wammer
//
//  Created by kchiu on 12/11/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAImportSettingsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *photoImportCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *pendingFilesCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *backupToPCCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *backupToCloudCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *upgradeAccountCell;

@end
