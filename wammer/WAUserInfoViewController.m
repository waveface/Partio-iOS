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
	__weak WAUser *wMainUser = wSelf.user;
	
	NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew;
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	
	[self irObserveObject:wMainUser keyPath:@"nickname" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		wSelf.userNameLabel.text = (NSString *)toValue;
		
	}];
	
	[self irObserveObject:self.user keyPath:@"email" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
		
		wSelf.userEmailLabel.text = (NSString *)toValue;

	}];
	
	[self irObserveObject:ri keyPath:@"networkState" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {

		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			WARemoteInterface *ri = [WARemoteInterface sharedInterface];
			if ([ri hasReachableStation]) {
				wSelf.connectionTableViewCell.accessoryView = nil;
				wSelf.connectionTableViewCell.detailTextLabel.text = ri.monitoredHostNames[1];
			} else if (ri.monitoredHosts && [ri hasReachableCloud]) {
				wSelf.connectionTableViewCell.accessoryView = nil;
				wSelf.connectionTableViewCell.detailTextLabel.text = ri.monitoredHostNames[0];
			} else {
				UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				[activity startAnimating];
				wSelf.connectionTableViewCell.accessoryView = activity;
				wSelf.connectionTableViewCell.detailTextLabel.text = NSLocalizedString(@"SEARCHING_NETWORK_SUBTITLE", @"Subtitle of searching network in setup done page.");
			}
		}];

	}];
	
	self.deviceNameLabel.text = WADeviceName();
  
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

	[aTV deselectRowAtIndexPath:indexPath animated:YES];
	
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

	if ([superAnswer isEqualToString:@"VERSION"])
		return [[NSBundle mainBundle] displayVersionString];
	
	return NSLocalizedString(superAnswer, nil);

}

@end
