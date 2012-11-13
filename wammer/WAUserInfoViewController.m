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

- (void) handleRemoteInterfaceUpdateStatusChanged:(WASyncStatus)syncing;

@property (nonatomic, readonly, assign) BOOL syncing;

@end


@implementation WAUserInfoViewController
@synthesize syncTableViewCell;
@synthesize contactTableViewCell;
@synthesize stationNagCell;
@synthesize serviceTableViewCell;
@synthesize lastSyncDateLabel;
@synthesize numberOfPendingFilesLabel;
@synthesize numberOfFilesNotOnStationLabel;
@synthesize stationNagLabel;
@synthesize userEmailLabel;
@synthesize userNameLabel;
@synthesize deviceNameLabel;
@synthesize managedObjectContext;
@synthesize user;
@synthesize activity;

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
	
	activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	
	activity.hidesWhenStopped = YES;
	activity.hidden = YES;
	
	activity.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin |
	UIViewAutoresizingFlexibleHeight |
	UIViewAutoresizingFlexibleLeftMargin |
	UIViewAutoresizingFlexibleRightMargin |
	UIViewAutoresizingFlexibleTopMargin |
	UIViewAutoresizingFlexibleWidth;
	
	activity.frame = CGRectMake(300.0-10.0-18.0, 14.0, 20.0, 20.0);	

	[self.syncTableViewCell insertSubview:activity atIndex:0];
  [self.tableView reloadData];
	
	__weak WAUserInfoViewController *wSelf = self;
	__weak WADataStore *wDataStore = [WADataStore defaultStore];
	__weak WAUser *wMainUser = wSelf.user;
	__weak WASyncManager *wBlobSyncManager = [self syncManager];
	__weak WARemoteInterface *wRemoteInterface = [WARemoteInterface sharedInterface];
	
	NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew;
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	
	[self irObserveObject:ri keyPath:@"isPerformingAutomaticRemoteUpdates" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		[wSelf handleRemoteInterfaceUpdateStatusChanged:[wSelf isSyncing]];

	}];
	
	[self irObserveObject:wBlobSyncManager keyPath:@"fileSyncOperationQueue.operationCount" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {

		// avoid blinking sync table view
		if (![wSelf isSyncing]) {

			[wSelf handleRemoteInterfaceUpdateStatusChanged:[wSelf isSyncing]];

		}

	}];
	
	[self irObserveObject:wDataStore keyPath:@"lastSyncSuccessDate" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
//		NSDate *date = [wDataStore lastSyncSuccessDate];
//
//		wSelf.lastSyncDateLabel.text = date ? [[IRRelativeDateFormatter sharedFormatter] stringFromDate:date] : nil;
		
	}];
	
	[self irObserveObject:wBlobSyncManager keyPath:@"numberOfFiles" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		wSelf.numberOfPendingFilesLabel.text = [toValue stringValue];
		
	}];
	
	[self irObserveObject:self.user keyPath:@"mainStorage.numberOfUnsyncedObjectsInQueue" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		wSelf.numberOfFilesNotOnStationLabel.text = [toValue stringValue];
		
	}];
	
	NSString * (^nagLabelTitle)(NSUInteger, BOOL) = ^ (NSUInteger level, BOOL hasStation) {
	
		return (
		
			(level == 0) ? (hasStation ?
				NSLocalizedString(
					@"USER_INFO_NAG_LEVEL_0_WITH_STATION",
					@"Title to show when user has a station but have not activated the account") :
				NSLocalizedString(
					@"USER_INFO_NAG_LEVEL_0_WITHOUT_STATION",
					@"Title to show when user has no station and have not activated the account")) :
			
			(level == 1) ? (hasStation ?
				NSLocalizedString(
					@"USER_INFO_NAG_LEVEL_1_WITH_STATION",
					@"Title to show when user has a station, and still have ample storage on the Cloud") :
				NSLocalizedString(
					@"USER_INFO_NAG_LEVEL_1_WITHOUT_STATION",
					@"Title to show when user has no station, and still have ample storage on the Cloud")) :
			
			(level == 2) ? (hasStation ?
				NSLocalizedString(
					@"USER_INFO_NAG_LEVEL_2_WITH_STATION",
					@"Title to show when user has a station, and is using up most of the storage on the Cloud") :
				NSLocalizedString(
					@"USER_INFO_NAG_LEVEL_2_WITHOUT_STATION",
					@"Title to show when user has no station, and is using up most of the storage on the Cloud")) :
			
			(level == 3) ? (hasStation ?
				NSLocalizedString(
					@"USER_INFO_NAG_LEVEL_3_WITH_STATION",
					@"Title to show when user has a station, and have exhausted storage on the Cloud") :
				NSLocalizedString(
					@"USER_INFO_NAG_LEVEL_3_WITHOUT_STATION",
					@"Title to show when user has no station, and have exhausted storage on the Cloud")) :
			
			nil
			
		);
	
	};
	
	[self irObserveObject:self.user keyPath:@"mainStorage.queueStatus" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		wSelf.stationNagLabel.text = nagLabelTitle([wSelf.user.mainStorage.queueStatus integerValue], [wRemoteInterface hasReachableStation]);
				
	}];
	
	[self irObserveObject:wRemoteInterface keyPath:@"networkState" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		wSelf.stationNagLabel.text = nagLabelTitle([wSelf.user.mainStorage.queueStatus integerValue], [wRemoteInterface hasReachableStation]);
		
		if ([wSelf isViewLoaded]) {
		
			UITableView *tv = wSelf.tableView;
			
			[tv beginUpdates];
			[tv reloadSections:[NSIndexSet indexSetWithIndex:[tv indexPathForCell:wSelf.serviceTableViewCell].section] withRowAnimation:UITableViewRowAnimationAutomatic];
			[tv endUpdates];
			
			wSelf.serviceTableViewCell.alpha = 1;
		
		}
		
	}];
	
	[self irObserveObject:wMainUser keyPath:@"nickname" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		wSelf.userNameLabel.text = (NSString *)toValue;
		
	}];
	
	[self irObserveObject:self.user keyPath:@"email" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
		
		wSelf.userEmailLabel.text = (NSString *)toValue;

	}];
	
	self.deviceNameLabel.text = WADeviceName();
  
	[self.photoImportSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]];
	
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

- (void) viewDidUnload {
  
	[self setSyncTableViewCell:nil];
	[self setLastSyncDateLabel:nil];
	[self setNumberOfPendingFilesLabel:nil];
	[self setNumberOfFilesNotOnStationLabel:nil];
	[self setStationNagLabel:nil];
	[self setUserEmailLabel:nil];
	[self setUserNameLabel:nil];
	[self setDeviceNameLabel:nil];
	[self setContactTableViewCell:nil];
	
	[self setStationNagCell:nil];
	[self setServiceTableViewCell:nil];
  [self setPhotoImportSwitch:nil];
  [super viewDidUnload];
	
}

- (void) handleRemoteInterfaceUpdateStatusChanged:(WASyncStatus)syncing {

	if (![NSThread isMainThread]) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
		
			[self handleRemoteInterfaceUpdateStatusChanged:syncing];
			
		});
		
		return;
	
	}
	
	UITableViewCell *cell = self.syncTableViewCell;
	if (syncing) {
		
		WARemoteInterface *ri = [WARemoteInterface sharedInterface];
		if (syncing == WASyncStatusConnected) {
			
			cell.textLabel.text = NSLocalizedString(@"SYNC_BUTTON_CAPTION_WITH_PERSISTENT_CONNECTION", @"Caption to show a persistent connection to station is held.");
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			[self.activity stopAnimating];
			
		} else {
			if ([ri hasReachableStation]) {
			
				cell.textLabel.text = NSLocalizedString(@"SYNC_BUTTON_CAPTION_WITH_STATION_CONNECTED", @"Caption to show in account info when station is connected");
		
			} else {

				cell.textLabel.text = NSLocalizedString(@"SYNC_BUTTON_NORMAL_TITLE", @"Caption to show when app is syncing data without station");
		
			}

			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			[self.activity startAnimating];
		}
		
	} else {
	
		cell.textLabel.text = NSLocalizedString(@"SYNC_BUTTON_USABLE_TITLE", @"Caption to show when app is not syncing data, but sync is usable");
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		[self.activity stopAnimating];
		
		IRTableView *tv = self.tableView;
		NSUInteger sectionIndex = [tv indexPathForCell:self.syncTableViewCell].section;

		[tv beginUpdates];
		[tv reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
		[tv endUpdates];

	}

}

- (void) tableView:(UITableView *)aTV didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *hitCell = [aTV cellForRowAtIndexPath:indexPath];
	
	if (hitCell == syncTableViewCell) {
	
		[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];
		[[self syncManager] performSyncNow];
		
	} else if (hitCell == stationNagCell) {
	
		NSString *title = NSLocalizedString(@"STREAM_ABOUT_TITLE", @"Title for About Stream dialog");
		
		NSString *message = NSLocalizedString(@"STREAM_ABOUT_TEXT", @"Text for About Stream dialog");
	
		NSString *okayTitle = NSLocalizedString(@"ACTION_OKAY", nil);
		IRAction *okayAction = [IRAction actionWithTitle:okayTitle block:nil];
		
		NSString *moreInfoTitle = NSLocalizedString(@"ACTION_MORE_INFO", nil);
		IRAction *moreInfoAction = [IRAction actionWithTitle:moreInfoTitle block:^{
			
			NSString *urlString = [[NSUserDefaults standardUserDefaults] stringForKey:WAStreamFeaturesURL];
			
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
			
		}];
	
		[[IRAlertView alertViewWithTitle:title message:message cancelAction:okayAction otherActions:[NSArray arrayWithObject:moreInfoAction]] show];
	
	} else if (hitCell == contactTableViewCell) {

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
	
	if ([superAnswer isEqualToString:@"PHOTO_IMPORT_FOOTER"]) {
		WADataStore *dataStore = [WADataStore defaultStore];
		WAArticle *article = [dataStore fetchLatestLocalImportedArticleUsingContext:[dataStore disposableMOC]];
		if (article) {
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
			NSString *dateString = [dateFormatter stringFromDate:article.creationDate];
			return [NSString stringWithFormat:NSLocalizedString(@"LAST_IMPORT_TIME", @"In Account Info Photo Import Section"), dateString];
		}
		return NSLocalizedString(@"START_PHOTO_IMPORT_DESCRIPTION", @"In Account Info Photo Import Section");
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

- (IBAction)handlePhotoImportSwitchChanged:(id)sender {

	UISwitch *photoImportSwitch = sender;
	if ([photoImportSwitch isOn]) {
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAPhotoImportEnabled];
	} else {
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAPhotoImportEnabled];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];

}

@end
