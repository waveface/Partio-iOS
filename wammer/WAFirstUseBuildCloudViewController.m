//
//  WAFirstUseBuildCloudViewController.m
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseBuildCloudViewController.h"

@interface WAFirstUseBuildCloudViewController ()

@end

@implementation WAFirstUseBuildCloudViewController

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
	self.connectedHost.hidden = YES;
	self.view.backgroundColor = [UIColor colorWithRed:203.0f/255.0f green:227.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
	__weak WAFirstUseBuildCloudViewController *wSelf = self;
	int64_t delayInSeconds = 1.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[wSelf.connectActivity stopAnimating];
		self.connectedHost.hidden = NO;
	});
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableView delegates

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *hitCell = [tableView cellForRowAtIndexPath:indexPath];
	if (hitCell == self.connectionCell) {
		[self.connectActivity startAnimating];
		self.connectedHost.hidden = YES;
		__weak WAFirstUseBuildCloudViewController *wSelf = self;
		int64_t delayInSeconds = 1.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[wSelf.connectActivity stopAnimating];
			self.connectedHost.hidden = NO;
		});
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];

}

@end
