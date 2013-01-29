//
//  WAUserDetailViewController.m
//  wammer
//
//  Created by Shen Steven on 1/25/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAUserDetailViewController.h"
#import "IRObservings.h"
#import "WADataStore.h"
#import "WAUser.h"
#import "WARemoteInterface.h"
#import "WAOverlayBezel.h"
#import "UIKit+IRAdditions.h"

@interface WAUserDetailViewController ()

@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation WAUserDetailViewController

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
  __weak WAUserDetailViewController *wSelf = self;
  
  NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew;

  [self irObserveObject:self.user
				keyPath:@"email"
				options:options
				context:nil
			  withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
				
				wSelf.userEmailTableCell.textLabel.text = (NSString *)toValue;
				
			  }];
  
  [self irObserveObject:self.user
				keyPath:@"nickname"
				options:options
				context:nil
			  withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
				
				wSelf.userNameTableCell.textLabel.text = (NSString*)toValue;
				
			  }];

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IRAlertView *)newSnsConnectAlertView {
  
  __weak WAUserDetailViewController *wSelf = self;
  
  NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
  IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
	
  }];
  
  IRAction *deleteAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_DELETE", @"The label on the confirmation dialog to make sure user want to delete account or not") block:^{

	[wSelf accountDidDelete];
	
  }];
  
  IRAlertView *alertView = [IRAlertView alertViewWithTitle:NSLocalizedString(@"ACCOUNT_DELETION_TITLE", @"The title of dialog to confirm user want to delete account or not.")
												   message:NSLocalizedString(@"ACCOUNT_DELETION_MSG", @"The message in the dialog to confirm user want to delete account or not.")
											  cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:deleteAction, nil]];
  
  return alertView;
  
}


- (void) accountDidDelete {
  
  WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
  [busyBezel showWithAnimation:WAOverlayBezelAnimationFade];

  [[WARemoteInterface sharedInterface] deleteUserWithEmailSentOnSuccess:^{
	
	dispatch_async(dispatch_get_main_queue(), ^{

	  [busyBezel dismiss];
	  IRAlertView *alertView = [IRAlertView alertViewWithTitle:NSLocalizedString(@"ACCOUNT_TITLE_DELETION_MAIL_SENT", @"Shows the final dialog to tell user to receive email to complete the account deletion process.")
													   message:NSLocalizedString(@"ACCOUNT_MSG_DELETION_MAIL_SENT", @"Shows the final dialog to tell user to receive email to complete the account deletion process")
												  cancelAction:[IRAction actionWithTitle:NSLocalizedString(@"ACTION_OK", nil) block:nil]
												  otherActions:nil];
	  [alertView show];
	});
	
  } onFailure:^(NSError *error) {
	
	dispatch_async(dispatch_get_main_queue(), ^{
	  [busyBezel dismiss];
	  WAOverlayBezel *errorBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
	  [errorBezel show];
	});
	
  }];
  
}

- (void) accountDeletionTapped {

  [[self newSnsConnectAlertView] show];
  [self.accountDeleteionTableCell setSelected:NO];
  
}

- (NSUInteger) supportedInterfaceOrientations {
  
  if (isPad())
    return UIInterfaceOrientationMaskAll;
  else
    return UIInterfaceOrientationMaskPortrait;
  
}

- (BOOL) shouldAutorotate {
  
  return YES;
  
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
  
  return cell;
  
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

  UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
  
  if (selectedCell == self.accountDeleteionTableCell) {
	
	[self accountDeletionTapped];
	
  } else {
	
  }

}

@end
