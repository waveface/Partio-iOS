//
//  WAUserInfoViewController.m
//  wammer
//
//  Created by Evadne Wu on 12/1/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAUserInfoViewController.h"

#import "WARemoteInterface.h"
#import "WARemoteInterface+WebSocket.h"
#import "WARemoteInterface+ScheduledDataRetrieval.h"
#import "WADefines.h"

#import "WAReachabilityDetector.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WANavigationController.h"

#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"
#import "WASyncManager.h"
#import "IRMailComposeViewController.h"
#import "IRRelativeDateFormatter+WAAdditions.h"
#import "WAAppDelegate_iOS.h"

@interface WAUserInfoViewController ()

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAUser *user;

@end


@implementation WAUserInfoViewController

+ (id) controllerWithWrappingNavController:(WANavigationController **)outNavController {
  
  NSString *name = NSStringFromClass([self class]);
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  UIStoryboard *sb = [UIStoryboard storyboardWithName:name bundle:bundle];
  
  WANavigationController *navC = (WANavigationController *)[sb instantiateInitialViewController];
  NSCParameterAssert([navC isKindOfClass:[WANavigationController class]]);
  
  navC.title = NSLocalizedString(@"USER_INFO_CONTROLLER_TITLE", @"Settings for User popover");
  WAUserInfoViewController *uiVC = (WAUserInfoViewController *)navC.topViewController;
  NSCParameterAssert([uiVC isKindOfClass:[WAUserInfoViewController class]]);
  
  if (outNavController)
    *outNavController = navC;
  
  return uiVC;
  
}

- (void) irConfigure {
  
  [super irConfigure];
  
  self.title = NSLocalizedString(@"USER_INFO_CONTROLLER_TITLE", @"Settings for User popover");
  self.tableViewStyle = UITableViewStyleGrouped;
  
  self.persistsStateWhenViewWillDisappear = NO;
  self.restoresStateWhenViewWillAppear = NO;
  
}

+ (NSSet *) keyPathsForValuesAffectingContentSizeForViewInPopover {
  
  return [NSSet setWithObjects:
	
	@"tableView.contentInset",
	@"tableView.contentSize",
	
	nil];
  
}

- (CGSize) contentSizeForViewInPopover {
  
  return (CGSize){
    
    320,
    self.tableView.contentInset.top + self.tableView.contentSize.height + self.tableView.contentInset.bottom
    
  };
  
}

- (void) viewDidLoad {
  
  [super viewDidLoad];
  
  [self.tableView reloadData];
  
  __weak WAUserInfoViewController *wSelf = self;
  
  NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew;
  WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
  
  [self irObserveObject:self.user keyPath:@"email" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    
    wSelf.userEmailLabel.text = (NSString *)toValue;
    
  }];
  
  [self irObserveObject:ri keyPath:@"networkState" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      WARemoteInterface *ri = [WARemoteInterface sharedInterface];
      if ([ri hasReachableStation]) {
        wSelf.connectionTableViewCell.accessoryView = nil;
        wSelf.connectionTableViewCell.detailTextLabel.text = [ri.monitoredHosts[0] name];
      } else if ([ri hasReachableCloud]) {
        wSelf.connectionTableViewCell.accessoryView = nil;
        wSelf.connectionTableViewCell.detailTextLabel.text = NSLocalizedString(@"CLOUD_NAME", @"AOStream Cloud Name");
      } else {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activity startAnimating];
        wSelf.connectionTableViewCell.accessoryView = activity;
        wSelf.connectionTableViewCell.detailTextLabel.text = NSLocalizedString(@"SEARCHING_NETWORK_SUBTITLE", @"Subtitle of searching network in setup done page.");
      }
    }];
    
  }];

  self.versionCell.textLabel.text = [[NSBundle mainBundle] displayVersionString];

}

- (void) irObserveObject:(id)target keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context withBlock:(IRObservingsCallbackBlock)block {
  
  [super irObserveObject:target keyPath:keyPath options:options context:context withBlock:block];
  
  if (block)
    block(NSKeyValueChangeSetting, nil, [target valueForKeyPath:keyPath], nil, YES);
  
}

- (void) viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];
  
  [self.tableView reloadData];
  
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

- (NSUInteger) supportedInterfaceOrientations {
  
  if (isPad())
    return UIInterfaceOrientationMaskAll;
  else
    return UIInterfaceOrientationMaskPortrait;
  
}

- (BOOL) shouldAutorotate {
  
  return YES;
  
}

- (void) tableView:(UITableView *)aTV didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *hitCell = [aTV cellForRowAtIndexPath:indexPath];
  
  if (hitCell == self.contactTableViewCell) {
    
    if (![IRMailComposeViewController canSendMail])
      return;
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *infoDictionary = [bundle irInfoDictionary];
    NSString *recipient = [infoDictionary objectForKey:WAFeedbackRecipient];
    NSArray *recipients = [NSArray arrayWithObject:recipient];
    NSString *subject = nil;
    NSString *body = nil;
    
    __weak WAUserInfoViewController *wSelf = self;
    
    IRMailComposeViewController *mcVC = [IRMailComposeViewController controllerWithMessageToRecipients:recipients withSubject:subject messageBody:body inHTML:NO completion:^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
      
      [controller dismissViewControllerAnimated:YES completion:nil];
      
    }];
    
    switch ([UIDevice currentDevice].userInterfaceIdiom) {
        
      case UIUserInterfaceIdiomPad: {
        mcVC.modalPresentationStyle = UIModalPresentationFormSheet;
        break;
      }
        
      default:
        break;
        
    }
    
    
    [wSelf presentViewController:mcVC animated:YES completion:nil];
    
  }
  
  if (hitCell == self.logoutCell) {

    WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS *)AppDelegate();
    IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
    IRAction *signOutAction = [IRAction
			 actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil)
			 block: ^ {
			   if ([appDelegate respondsToSelector:@selector(applicationRootViewControllerDidRequestReauthentication:)])
			     [appDelegate performSelector:@selector( applicationRootViewControllerDidRequestReauthentication: ) withObject:nil];
			 }];

    [[IRAlertView alertViewWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil)
		         message:NSLocalizedString(@"SIGN_OUT_CONFIRMATION", nil)
		    cancelAction:cancelAction
		    otherActions:@[signOutAction]] show];

  }
  
  [aTV deselectRowAtIndexPath:indexPath animated:NO];
  
}

- (UITableViewCell *) tableView:(UITableView *)aTV cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  UITableViewCell *cell = [super tableView:aTV cellForRowAtIndexPath:indexPath];
  cell.textLabel.text = NSLocalizedString(cell.textLabel.text, nil);
  cell.detailTextLabel.text = NSLocalizedString(cell.detailTextLabel.text, nil);
  
  return cell;
  
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  
  NSString *superAnswer = [super tableView:tableView titleForHeaderInSection:section];
  
  return NSLocalizedString(superAnswer, nil);
  
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  
  NSString *superAnswer = [super tableView:tableView titleForFooterInSection:section];
  
  return NSLocalizedString(superAnswer, nil);
  
}

@end
