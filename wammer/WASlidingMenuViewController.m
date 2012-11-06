//
//  WASlidingMenuViewController.m
//  wammer
//
//  Created by Shen Steven on 9/16/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASlidingMenuViewController.h"
#import "WAAppDelegate.h"
#import "WADefines.h"
#import "WANavigationController.h"
#import "WATimelineViewControllerPhone.h"
#import "WAUserInfoViewController.h"
#import "WAOverlayBezel.h"
#import "WAPhotoImportManager.h"
#import "WADataStore.h"
#import "WAPhotoStreamViewController.h"

@interface WASlidingMenuViewController () {
	NSArray *menuItems;
}

@end

@implementation WASlidingMenuViewController

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
	menuItems = @[
		NSLocalizedString(@"SLIDING_MENU_TITLE_TIMELINE", @"Title for Timeline in the sliding menu"),
		NSLocalizedString(@"PHOTOS_TITLE", @"In sliding menu"),
		NSLocalizedString(@"SLIDING_MENU_TITLE_COLLECTION", @"Title for Collection in the sliding menu"),
		NSLocalizedString(@"SLIDING_MENU_TITLE_SETTINGS", @"Title for Settings in the sliding menu")
	];
	
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void) handleUserInfo {
	
	[self.viewDeckController closeLeftView];
	
	WANavigationController *navC = nil;
	WAUserInfoViewController *userInfoVC = [WAUserInfoViewController controllerWithWrappingNavController:&navC];
	
	__weak WASlidingMenuViewController *wSelf = self;
	
	UIImage *menuImage = [UIImage imageNamed:@"menu"];
	UIButton *slidingMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
	slidingMenuButton.frame = (CGRect) {CGPointZero, menuImage.size};
	[slidingMenuButton setBackgroundImage:menuImage forState:UIControlStateNormal];
	[slidingMenuButton setBackgroundImage:[UIImage imageNamed:@"menuHL"] forState:UIControlStateHighlighted];
	[slidingMenuButton setShowsTouchWhenHighlighted:YES];
	[slidingMenuButton addTarget:self.viewDeckController action:@selector(toggleLeftView) forControlEvents:UIControlEventTouchUpInside];
	
	userInfoVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:slidingMenuButton];
	
	
	IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
	IRAction *signOutAction = [IRAction
														 actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil)
														 block: ^ {
															 if ([wSelf.delegate respondsToSelector:@selector(applicationRootViewControllerDidRequestReauthentication:)])
																 [wSelf.delegate applicationRootViewControllerDidRequestReauthentication:nil];
														 }];
	
	userInfoVC.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) action:^{
		
		[[IRAlertView alertViewWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil)
														 message:NSLocalizedString(@"SIGN_OUT_CONFIRMATION", nil)
												cancelAction:cancelAction
												otherActions:@[signOutAction]] show];
		
	}];
	
	//	[self presentViewController:navC animated:YES completion:nil];
	[self.viewDeckController setCenterController:navC];
	
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
	return [menuItems count];
	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
  
	cell.textLabel.text = menuItems[[indexPath row]];
	
	return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.row) {
			
		case 0: {
			[self.viewDeckController closeLeftView];
			WADayViewController *swVC = [[WADayViewController alloc] init];
			WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:swVC];
			self.viewDeckController.centerController = navVC;
			break;
		}
		case 1: {
			[self.viewDeckController closeLeftView];
			WAPhotoStreamViewController *photoVC = [[WAPhotoStreamViewController alloc] init];
			UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:photoVC];
			self.viewDeckController.centerController = navVC;
			break;
		}
		case 3: { // Settings
			
			[self handleUserInfo];
			break;
			
		}
	}
}

@end
