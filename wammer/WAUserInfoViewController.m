//
//  WAUserInfoViewController.m
//  wammer
//
//  Created by Evadne Wu on 12/1/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAUserInfoViewController.h"

#import "WARemoteInterface.h"
#import "WADefines.h"

#import "WAReachabilityDetector.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"
#import "WABlobSyncManager.h"
#import "IRMailComposeViewController.h"


@interface WAUserInfoViewController ()
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAUser *user;

- (void) handleRemoteInterfaceUpdateStatusChanged:(BOOL)syncing;

@end


@implementation WAUserInfoViewController
@synthesize syncTableViewCell;
@synthesize contactTableViewCell;
@synthesize stationNagCell;
@synthesize lastSyncDateLabel;
@synthesize numberOfPendingFilesLabel;
@synthesize numberOfFilesNotOnStationLabel;
@synthesize stationNagLabel;
@synthesize userEmailLabel;
@synthesize userNameLabel;
@synthesize deviceNameLabel;
@synthesize managedObjectContext;
@synthesize user;

+ (id) controllerWithWrappingNavController:(UINavigationController **)outNavController {

	NSString *name = NSStringFromClass([self class]);
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	UIStoryboard *sb = [UIStoryboard storyboardWithName:name bundle:bundle];
	
	UINavigationController *navC = (UINavigationController *)[sb instantiateInitialViewController];
	NSCParameterAssert([navC isKindOfClass:[UINavigationController class]]);
	
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
	
	switch (UI_USER_INTERFACE_IDIOM()){
	
		case UIUserInterfaceIdiomPhone: {
		
			self.tableView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
			self.tableView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"lightBackground"]];
			
			break;
		
		}
		
	}
	
	__weak WAUserInfoViewController *wSelf = self;
	__weak WADataStore *wDataStore = [WADataStore defaultStore];
	__weak WAUser *wMainUser = wSelf.user;
	__weak WABlobSyncManager *wBlobSyncManager = [WABlobSyncManager sharedManager];
	__weak WARemoteInterface *wRemoteInterface = [WARemoteInterface sharedInterface];
	
	NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew;
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	
	[self irObserveObject:ri keyPath:@"isPerformingAutomaticRemoteUpdates" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		[wSelf handleRemoteInterfaceUpdateStatusChanged:[toValue boolValue]];
		
	}];
	
	[self irObserveObject:wDataStore keyPath:@"lastContentSyncDate" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {

		wSelf.lastSyncDateLabel.text = [[IRRelativeDateFormatter sharedFormatter] stringFromDate:wDataStore.lastContentSyncDate];
		
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
			[tv reloadSections:[NSIndexSet indexSetWithIndex:[tv indexPathForCell:wSelf.syncTableViewCell].section] withRowAnimation:UITableViewRowAnimationAutomatic];
			[tv endUpdates];
			
			wSelf.syncTableViewCell.alpha = 1;
		
		}
		
	}];
	
	[self irObserveObject:wMainUser keyPath:@"nickname" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	
		wSelf.userNameLabel.text = (NSString *)toValue;
		
	}];
	
	[self irObserveObject:self.user keyPath:@"email" options:options context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
		
		wSelf.userEmailLabel.text = (NSString *)toValue;

	}];
  
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
  [super viewDidUnload];	
	
}

- (void) handleRemoteInterfaceUpdateStatusChanged:(BOOL)syncing {

	UITableViewCell *cell = self.syncTableViewCell;
	if (syncing) {
		
		cell.textLabel.text = NSLocalizedString(@"SYNC_BUTTON_NORMAL_TITLE", @"Caption to show when app is syncing data");
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
	} else {
	
		cell.textLabel.text = NSLocalizedString(@"SYNC_BUTTON_USABLE_TITLE", @"Caption to show when app is not syncing data, but sync is usable");
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	}

}

- (void) tableView:(UITableView *)aTV didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *hitCell = [aTV cellForRowAtIndexPath:indexPath];
	
	if (hitCell == syncTableViewCell) {
	
		[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];
		
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
		
			[controller dismissModalViewControllerAnimated:YES];
		
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
	
	if ([superAnswer isEqualToString:@"LOCAL_PENDING_OBJECT_DESCRIPTION"]) {
	
		if (![[WARemoteInterface sharedInterface] hasWiFiConnection])
			return NSLocalizedString(@"LOCAL_PENDING_OBJECT_DESCRIPTION", @"Title to show explaining WiFi Sync");
		
		return nil;
	
	}
	
	if ([superAnswer isEqualToString:@"VERSION"])
		return [[NSBundle mainBundle] displayVersionString];
	
	return NSLocalizedString(superAnswer, nil);

}

@end
