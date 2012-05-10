//
//  WAUserInfoViewController.m
//  wammer
//
//  Created by Evadne Wu on 12/1/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAUserInfoViewController.h"
#import "WAUserInfoHeaderCell.h"

#import "WARemoteInterface.h"
#import "WADefines.h"

#import "WAReachabilityDetector.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"

#import "IASKAppSettingsViewController.h"
#import "WAPulldownRefreshView.h"


#define kConnectivitySection 2

@interface WAUserInfoViewController ()

@property (nonatomic, readwrite, retain) NSArray *monitoredHosts;
- (NSString *) titleForMonitoredHost:(NSURL *)anURL;

- (void) handleReachableHostsDidChange:(NSNotification *)aNotification;
- (void) handleReachabilityDetectorDidUpdate:(NSNotification *)aNotification;

- (void) handleRemoteInterfaceUpdateStatusChanged:(BOOL)isBusy;

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAUser *user;
@end


@implementation WAUserInfoViewController

@synthesize monitoredHosts;
@synthesize managedObjectContext;
@synthesize user;

- (void) irConfigure {

  [super irConfigure];
  
  self.title = NSLocalizedString(@"USER_INFO_CONTROLLER_TITLE", @"Settings for User popover");
	self.tableViewStyle = UITableViewStyleGrouped;
	
  self.persistsStateWhenViewWillDisappear = NO;
  self.restoresStateWhenViewDidAppear = NO;
	
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	__weak WAUserInfoViewController *wSelf = self;
	
	id helper = [ri irAddObserverBlock:^(id inOldValue, id inNewValue, NSKeyValueChange changeKind) {

		[wSelf handleRemoteInterfaceUpdateStatusChanged:[inNewValue boolValue]];
		
	} forKeyPath:@"isPerformingAutomaticRemoteUpdates" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
	
	__weak id wHelper = helper;
	
	[wSelf irPerformOnDeallocation:^{
	
		if (wHelper) {
			[ri irRemoveObservingsHelper:wHelper];
		}
		
	}];

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
	
	self.tableView.sectionHeaderHeight = 56;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
		
		self.tableView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
		self.tableView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"lightBackground"]];
		
	}
  
}

- (void) viewWillAppear:(BOOL)animated {

  [super viewWillAppear:animated];
	
  self.monitoredHosts = nil;
  [self.tableView reloadData];
	
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReachableHostsDidChange:) name:kWARemoteInterfaceReachableHostsDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReachabilityDetectorDidUpdate:) name:kWAReachabilityDetectorDidUpdateStatusNotification object:nil];
  
}

- (NSString *) titleForMonitoredHost:(NSURL *)anURL {

	if ([[anURL host] isEqualToString:[[WARemoteInterface sharedInterface].engine.context.baseURL host]])
		return NSLocalizedString(@"PROPER_NOUN_WF_CLOUD", @"Short label for the Cloud");

	return NSLocalizedString(@"PROPER_NOUN_WF_STATION", @"Short label for a particular Station");

}

- (void) handleReachableHostsDidChange:(NSNotification *)aNotification {

  NSParameterAssert([NSThread isMainThread]);
  
  self.monitoredHosts = ((WARemoteInterface *)aNotification.object).monitoredHosts;
  
  if (![self isViewLoaded])
    return;
  
  @try {

		[self.tableView beginUpdates];
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kConnectivitySection] withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView endUpdates];
  
  } @catch (NSException *exception) {

    [self.tableView reloadData];
    
  }

}

- (void) handleReachabilityDetectorDidUpdate:(NSNotification *)aNotification {

  NSParameterAssert([NSThread isMainThread]);

  if (![self isViewLoaded])
    return;

  @try {

		[self.tableView beginUpdates];
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kConnectivitySection] withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView endUpdates];
  
  } @catch (NSException *exception) {

    [self.tableView reloadData];
    
  }

}

- (void) handleRemoteInterfaceUpdateStatusChanged:(BOOL)isBusy {

	if (![self isViewLoaded])
		return;
	
	[self.tableView beginUpdates];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:
		[NSIndexPath indexPathForRow:0 inSection:0],
	nil] withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView endUpdates];

}

- (NSArray *) monitoredHosts {

  if (monitoredHosts)
    return monitoredHosts;
  
  self.monitoredHosts = [WARemoteInterface sharedInterface].monitoredHosts;
  return monitoredHosts;
	
}

- (void) setMonitoredHosts:(NSArray *)newMonitoredHosts {

  if (newMonitoredHosts == monitoredHosts)
    return;
  
  if ([newMonitoredHosts isEqualToArray:monitoredHosts])
    return;
  
  [self willChangeValueForKey:@"monitoredHosts"];
  monitoredHosts = newMonitoredHosts;
  [self didChangeValueForKey:@"monitoredHosts"];

}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

	return 5;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
  switch (section) {
			
    case 0:
      return 1;
		
    case 1:
      return 1;
			
		case kConnectivitySection:
			return [self.monitoredHosts count];
			
		case 3:
      return 2;
		
		case 4:
			return 2;
			
		case 5:
			return WAAdvancedFeaturesEnabled() ? 1 : 0;
			
    default:
      return 0;
			
  };
	
}

- (CGFloat) tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section {

	switch (section) {
		
		case 0:
			return 16;
		
		default:
			return aTableView.sectionHeaderHeight;
	
	}
	
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	switch (indexPath.section) {
	
		case 1: {
		
			switch (indexPath.row) {
				
				case 0:
					return 56.0f;
				
			}
			
		}
	
	}
	
	return tableView.rowHeight;

}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  if (section == 0)
    return nil;
	
  if (section == 1)
    return NSLocalizedString(@"USER_INFO_ACCOUNT_SECTION_TITLE", @"Title in User Section");
  
	if (section == kConnectivitySection)
    return NSLocalizedString(@"SYNCHRONIZATION_INFO", @"Synchronization Information in Account Info");
  
  if (section == 3)
    return NSLocalizedString(@"NOUN_STORAGE_QUOTA", @"Noun for storage quota.");
	
  if (section == 4)
    return NSLocalizedString(@"ABOUT_HEADER", @"In account information");

 return nil;

}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

	if (section == kConnectivitySection) {
	
		NSUInteger numberOfMonitoredHosts = [self.monitoredHosts count];

		if (numberOfMonitoredHosts == 0)
			return NSLocalizedString(@"ENDPOINT_REACHABILITY_STATUS_NO_ENDPOINTS_DESCRIPTION", @"Text to show when not even Cloud is there — a rare case");
		
		if (numberOfMonitoredHosts == 1)
			return NSLocalizedString(@"ENDPOINT_REACHABILITY_STATUS_CLOUD_ONLY_DESCRIPTION", @"Text to show when only Cloud is available");
		
		if ([[WARemoteInterface sharedInterface] hasReachableStation])
			return NSLocalizedString(@"ENDPOINT_REACHABILITY_STATUS_CLOUD_AND_STATION_AVAILABLE_DESCRIPTION", @"Text to show when Cloud and Station are both available");
		
		return NSLocalizedString(@"ENDPOINT_REACHABILITY_STATUS_STATION_NOT_AVAILABLE_DESCRIPTION", @"Text to show when Cloud is available, but the Station is not responsive");

	}
	
	return nil;

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	__block UITableViewCell *cell = nil;
	NSString * const kDefaultIdentifier = @"DefaultCell";
	NSString * const kValue1Identifier = @"Value1Cell";
	NSString * const kSubtitleCellIdentifier = @"SubtitleCell";
	
	UITableViewCell * (^createCell)(NSString *, UITableViewCellStyle) = ^ (NSString *anIdentifier, UITableViewCellStyle aStyle) {
		
		cell = [tableView dequeueReusableCellWithIdentifier:anIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:aStyle reuseIdentifier:anIdentifier];
		}
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		
		return cell;
		
	};
	
	UITableViewCell * (^anyCell)(void) = ^ {
		
		if (cell)
			return cell;
		
		cell = createCell(kValue1Identifier, UITableViewCellStyleValue1);
		return cell;
		
	};
		
  if (indexPath.section == 0) {
	
		switch (indexPath.row) {
		
			case 0: {
				
				cell = createCell(kDefaultIdentifier, UITableViewCellStyleDefault);
				
				WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
				
				if (ri.isPerformingAutomaticRemoteUpdates) {
				
					cell.textLabel.text = NSLocalizedString(@"SYNC_BUTTON_NORMAL_TITLE", @"Caption to show when app is syncing data");
				
					cell.selectionStyle = UITableViewCellSelectionStyleNone;

				} else {
				
					cell.textLabel.text = NSLocalizedString(@"SYNC_BUTTON_USABLE_TITLE", @"Caption to show when app is not syncing data, but sync is usable");
					
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				
				}
				
				cell.textLabel.textAlignment = UITextAlignmentCenter;
				
				break;
			}
		
		}
	
  } else if (indexPath.section == 1) {
		
		switch (indexPath.row) {
			
			case 0: {
				cell = createCell(kSubtitleCellIdentifier, UITableViewCellStyleSubtitle);
				cell.textLabel.text = self.user.nickname;
				cell.detailTextLabel.text = self.user.email;
				break;
			}
			
//			case 1: {
//				cell = anyCell();
//				cell.textLabel.text = NSLocalizedString(@"NOUN_USERNAME", @"username in account info");
//				cell.detailTextLabel.text = self.user.nickname;
//				break;
//			}
			
			default: {
				break;
			}
			
		}
		
	} else if (indexPath.section == kConnectivitySection) {
	
		cell = anyCell();
		
		if ([self.monitoredHosts count]) {
			
			NSURL *hostURL = [self.monitoredHosts objectAtIndex:indexPath.row];
			cell.textLabel.text = [self titleForMonitoredHost:hostURL];
			cell.detailTextLabel.text = NSLocalizedStringFromWAReachabilityState([[WARemoteInterface sharedInterface] reachabilityStateForHost:hostURL]);
			
		}
		
	} else if (indexPath.section == 3) {
		  
		cell = anyCell();
		
		NSNumber *used = self.user.mainStorage.numberOfObjectsCreatedInInterval;
		NSNumber *all = self.user.mainStorage.numberOfObjectsAllowedInInterval;
						
		switch ([indexPath row]) {
			
			case 0: {
			
				cell.textLabel.text = NSLocalizedString(@"OBJECTS_NOT_SYNCED_IN_QUEUE", @"in Account Information");
				cell.detailTextLabel.text = ([all isEqualToNumber:[NSNumber numberWithInteger:-1]]) ?
					NSLocalizedString(@"STORAGE_QUOTA_UNLIMITED_TITLE", nil):
					[NSString stringWithFormat:@"%@", all];
				
				break;
				
			}
			
			case 1: {
			
				cell.textLabel.text = NSLocalizedString(@"LAST_SYNCED_TIME", @"in Account Information");
				cell.detailTextLabel.text = @"2 days ago";
				
				break;
				
			}
			
			default:
				break;
			
		}
		
	} else if (indexPath.section == 4) {
	
		cell = anyCell();
		
		switch (indexPath.row) {
		
			case 0: {
			
				cell.textLabel.text = NSLocalizedString(@"NOUN_CURRENT_DEVICE", @"This Device");
				cell.detailTextLabel.text = [UIDevice currentDevice].name;

				break;
				
			}
			
			case 1: {
			
				cell.textLabel.text = NSLocalizedString(@"VERSION", @"Version in account info");
				cell.detailTextLabel.text = [[NSBundle mainBundle] displayVersionString];

				break;
				
			}
		}
	
	} else if (indexPath.section == 5) {
	
		cell = anyCell();
		
		switch (indexPath.row) {
		
			case 0: {
			
				cell.textLabel.text = NSLocalizedString(@"SETTINGS_TITLE", nil);
				cell.detailTextLabel.text = nil;
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
				break;
				
			}
		
		}
	
	}
	
	NSParameterAssert(cell);
  return cell;

}

- (void) tableView:(UITableView *)inTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	switch (indexPath.section) {
	
		case 0: {
		
			switch (indexPath.row) {
			
				case 0: {
				
					[inTableView deselectRowAtIndexPath:indexPath animated:YES];
					[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];
				
					break;
				
				}
			
			}
			
			break;
		
		}
	
		case 5: {
		
			switch (indexPath.row) {
			
				case 0: {
				
					IASKAppSettingsViewController *appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
					
					appSettingsViewController.delegate = self;
					appSettingsViewController.showDoneButton = NO;
					appSettingsViewController.showCreditsFooter = NO;
					
					[self.navigationController pushViewController:appSettingsViewController animated:YES];
				
					break;
				
				}
			
			}
		
			break;
			
		}
		
	}

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
  
	//[self irUnbind:@"contentSize"];

  [super viewDidUnload];	
	
}

@end
