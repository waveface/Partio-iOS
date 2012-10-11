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

@interface WASlidingMenuViewController ()

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
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) handleUserInfo {
	
	UINavigationController *navC = nil;
	WAUserInfoViewController *userInfoVC = [WAUserInfoViewController controllerWithWrappingNavController:&navC];

	__weak WASlidingMenuViewController *wSelf = self;
	__weak WAUserInfoViewController *wUserInfoVC = userInfoVC;

	userInfoVC.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemDone wiredAction:^(IRBarButtonItem *senderItem) {
	
		[wUserInfoVC.navigationController dismissViewControllerAnimated:YES completion:nil];
	
	}];

	userInfoVC.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) action:^{
	
		IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
	
		NSString *alertTitle = NSLocalizedString(@"ACTION_SIGN_OUT", nil);
		NSString *alertText = NSLocalizedString(@"SIGN_OUT_CONFIRMATION", nil);
	
		[[IRAlertView alertViewWithTitle:alertTitle
														 message:alertText
												cancelAction:cancelAction
												otherActions:[NSArray arrayWithObjects:
																			[IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) block: ^ {
		
			WAOverlayBezel *bezel = [WAOverlayBezel bezelWithStyle:WADefaultBezelStyle];
			[bezel show];
			[[WAPhotoImportManager defaultManager] cancelPhotoImportWithCompletionBlock:^{
			
				[((WAAppDelegate*)AppDelegate()) unsubscribeRemoteNotification];
			
				[bezel dismiss];
				
				if ([wSelf.delegate respondsToSelector:@selector(applicationRootViewControllerDidRequestReauthentication:)])
					[wSelf.delegate applicationRootViewControllerDidRequestReauthentication:nil];
				
			}];
		
		}],
																																																				
																																																				nil]] show];
	
	}];

	[self presentViewController:navC animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
	return 3;
	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
  
		switch(indexPath.row) {
			
			case 0:
				cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_TIMELINE", @"Title for Timeline in the sliding menu");
				break;
				
			case 1:
				cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_COLLECTION", @"Title for Collection in the sliding menu");
				break;
				
			case 2:
				cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_SETTINGS", @"Title for Settings in the sliding menu");
				break;
		}
	
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
	NSInteger row = indexPath.row;

	switch (row) {
			
		case 0: {
			WANavigationController *nav = (WANavigationController*)self.viewDeckController.centerController;
			[(WATimelineViewControllerPhone*)(nav.topViewController) jumpToToday];
			[self.viewDeckController closeLeftView];
			break;
		}
			
		case 1:
			break;
			
		case 2: // Settings
			[self handleUserInfo];
			break;
	}
}

@end
