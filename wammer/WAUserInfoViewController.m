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

#import "WASyncManager.h"
#import "WAPhotoImportManager.h"
#import "WAAppDelegate_iOS.h"

typedef enum WASyncStatus: NSUInteger {
	WASyncStatusNone = 0,
	WASyncStatusSyncing,
	WASyncStatusConnected
} WASyncStatus;


@interface WAUserInfoViewController ()

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAUser *user;

@property (nonatomic, readonly, assign) BOOL syncing;

@end


@implementation WAUserInfoViewController
@synthesize contactTableViewCell;
@synthesize serviceTableViewCell;
@synthesize numberOfPendingFilesLabel;
@synthesize userEmailLabel;
@synthesize userNameLabel;
@synthesize deviceNameLabel;
@synthesize managedObjectContext;
@synthesize user;

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
	__weak WASyncManager *wBlobSyncManager = [self syncManager];
	
	NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew;
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	
	[self irObserveObject:wBlobSyncManager keyPath:@"numberOfFiles" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		wSelf.numberOfPendingFilesLabel.text = [toValue stringValue];
		
	}];
		
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
  
  if (managedObjectContext)
    return managedObjectContext;
    
  managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return managedObjectContext;

}

- (WAUser *) user {

	if (user)
		return user;
	
	user = [[WADataStore defaultStore] mainUserInContext:self.managedObjectContext];
	return user;

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  
	switch ([UIDevice currentDevice].userInterfaceIdiom) {
		
		case UIUserInterfaceIdiomPad: {
			return YES;
		}
		
		default: {
			return interfaceOrientation == UIInterfaceOrientationPortrait;
		}
		
	}
  
}

- (void) tableView:(UITableView *)aTV didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *hitCell = [aTV cellForRowAtIndexPath:indexPath];
	
	if (hitCell == contactTableViewCell) {

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
	
	if ([superAnswer isEqualToString:@"SERVICE_INFO_FOOTER"]) {
	
		if ([[WARemoteInterface sharedInterface] hasWiFiConnection])
			return NSLocalizedString(@"SERVICE_INFO_WITH_WIFI", @"Title to show explaining WiFi Sync");
		else
			return NSLocalizedString(@"SERVICE_INFO_WITHOUT_WIFI", @"Title to show explaining WiFi Sync");
		
	}
	
	if ([superAnswer isEqualToString:@"SYNC_INFO_FOOTER"]) {
	
		WADataStore *dataStore = [WADataStore defaultStore];
		NSDate *date = [dataStore lastSyncSuccessDate];
		
		if (date) {
		
			NSString *dateString = [[IRRelativeDateFormatter sharedFormatter] stringFromDate:date];
			
			return [NSString stringWithFormat:
				NSLocalizedString(@"SYNC_INFO_FOOTER", @"In Account Info Sync Section"),
				dateString
			];
		
		}
		
		return nil;
		
	}
	
	if ([superAnswer isEqualToString:@"VERSION"])
		return [[NSBundle mainBundle] displayVersionString];
	
	return NSLocalizedString(superAnswer, nil);

}

+ (NSSet *) keyPathsForValuesAffectingSyncing {

	return [NSSet setWithObjects:
	
		@"remoteInterface.performingAutomaticRemoteUpdates",
		@"syncManager.operationQueue.operationCount",
	
	nil];

}

- (WARemoteInterface *) remoteInterface {
	
	return [WARemoteInterface sharedInterface];

}

- (WASyncManager *) syncManager {

	return [(WAAppDelegate_iOS *)AppDelegate() syncManager];

}

- (WASyncStatus) isSyncing {

	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	WASyncManager * const sm = [self syncManager];

	if (ri.performingAutomaticRemoteUpdates || sm.fileSyncOperationQueue.operationCount)
		return WASyncStatusSyncing;

	if (ri.webSocketConnected)
		return WASyncStatusConnected;

	return WASyncStatusNone;
}

@end
