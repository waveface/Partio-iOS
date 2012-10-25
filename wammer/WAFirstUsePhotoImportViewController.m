//
//  WAFirstUsePhotoImportViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUsePhotoImportViewController.h"

@interface WAFirstUsePhotoImportViewController ()

@end

@implementation WAFirstUsePhotoImportViewController

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
	self.navigationItem.hidesBackButton = YES;
	self.navigationItem.rightBarButtonItem.enabled = NO;
	self.view.backgroundColor = [UIColor colorWithRed:203.0f/255.0f green:227.0f/255.0f blue:234.0f/255.0f alpha:1.0f];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *hitCell = [tableView cellForRowAtIndexPath:indexPath];
	if (hitCell == self.enablePhotoImportCell) {
		self.enablePhotoImportCell.accessoryType = UITableViewCellAccessoryCheckmark;
		self.disablePhotoImportCell.accessoryType = UITableViewCellAccessoryNone;
		self.navigationItem.rightBarButtonItem.enabled = YES;
	} else if (hitCell == self.disablePhotoImportCell) {
		self.disablePhotoImportCell.accessoryType = UITableViewCellAccessoryCheckmark;
		self.enablePhotoImportCell.accessoryType = UITableViewCellAccessoryNone;
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];

}

@end
