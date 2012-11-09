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

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) WAUser *user;

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


	userInfoVC.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) action:^{
	
		IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
	
		NSString *alertTitle = NSLocalizedString(@"ACTION_SIGN_OUT", nil);
		NSString *alertText = NSLocalizedString(@"SIGN_OUT_CONFIRMATION", nil);
	
		[[IRAlertView alertViewWithTitle:alertTitle
														 message:alertText
												cancelAction:cancelAction
												otherActions:[NSArray arrayWithObjects:
																			[IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) block: ^ {
		
				
				if ([wSelf.delegate respondsToSelector:@selector(applicationRootViewControllerDidRequestReauthentication:)])
					[wSelf.delegate applicationRootViewControllerDidRequestReauthentication:nil];
				
		
		}], nil]] show];
	
	}];

//	[self presentViewController:navC animated:YES completion:nil];
	[self.viewDeckController setCenterController:navC];
	
}

- (NSManagedObjectContext *) managedObjectContext {
  
  if (_managedObjectContext)
    return _managedObjectContext;
	
  _managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return _managedObjectContext;
	
}

- (WAUser *) user {
	
	if (_user)
		return _user;
	
	_user = [[WADataStore defaultStore] mainUserInContext:self.managedObjectContext];
	return _user;
	
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
	return 6;
	
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
    if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
		
		switch(indexPath.row) {
			
			case 0: {
				cell.imageView.image = (self.user.avatar)? self.user.avatar: [UIImage imageNamed:@"WAUserGlyph"];
				cell.textLabel.text = self.user.nickname;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				break;
			}
				
			case 1:
				cell.imageView.image = [UIImage imageNamed:@"EventsIcon"];
				cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_EVENTS", @"Title for Events in the sliding menu");
				break;
				
			case 2:
				cell.imageView.image = [UIImage imageNamed:@"PhotosIcon"];
				cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_PHOTOS", @"Title for Photos in the sliding menu");
				break;
				
			case 3:
				cell.imageView.image = [UIImage imageNamed:@"CollectionIcon"];
				cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_COLLECTIONS", @"Title for Collections in the sliding menu");
				break;
				
			case 4:
				cell.imageView.image = [UIImage imageNamed:@"CalIcon"];
				cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_CALENDAR", @"Title for Calendar in the sliding menu");
				break;
				
			case 5:
				cell.imageView.image = [UIImage imageNamed:@"SettingsIcon"];
				cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_SETTINGS", @"Title for Settings in the sliding menu");
				break;
		}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	
	cell.textLabel.textColor = [UIColor whiteColor];
	cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:16.0];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
  
	switch(indexPath.row) {
			
		case 0:
			break;
			
		case 1:
			cell.backgroundColor = [UIColor colorWithRed:0.957 green:0.376 blue:0.298 alpha:1.0];
			break;
			
		case 2:
			cell.backgroundColor = [UIColor colorWithRed:0.463 green:0.667 blue:0.8 alpha:1.0];
			break;
			
		case 3:
			cell.backgroundColor = [UIColor colorWithRed:1 green:0.651 blue:0 alpha:1.0];
			break;
			
		case 4:
			cell.backgroundColor = [UIColor colorWithRed:0.486 green:0.612 blue:0.208 alpha:1.0];
			break;
			
		case 5:
			cell.backgroundColor = [UIColor colorWithRed:0.176 green:0.278 blue:0.475 alpha:1.0];
			break;
	}
	
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
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	
	NSInteger row = indexPath.row;

	switch (row) {
		
		case 0:
			break;
			
		case 1: { // Events

			[self.viewDeckController closeLeftView];
			WADayViewController *swVC = [[WADayViewController alloc] init];

			WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:swVC];
			self.viewDeckController.centerController = navVC;
			
			break;
		}
			
		case 2:
			break;
			
		case 3:
			break;
			
		case 4:
			break;
			
		case 5: { // Settings
			
			[self handleUserInfo];
			break;
			
		}
	}
}

#pragma mark - IIViewDeckDelegate protocol

- (void)viewDeckController:(IIViewDeckController *)viewDeckController applyShadow:(CALayer *)shadowLayer withBounds:(CGRect)rect {
	// No shadow
}

@end
