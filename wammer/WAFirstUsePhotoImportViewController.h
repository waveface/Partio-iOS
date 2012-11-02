//
//  WAFirstUsePhotoImportViewController.h
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUsePhotoImportViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITableViewCell *enablePhotoImportCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *disablePhotoImportCell;
@property (nonatomic, readwrite) BOOL isFromConnectServicesPage;

@end
