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

#define kConnectivitySection 1

@interface WAUserInfoViewController ()

@property (nonatomic, readwrite, retain) NSArray *monitoredHosts;
- (NSString *) titleForMonitoredHost:(NSURL *)anURL;

- (void) handleReachableHostsDidChange:(NSNotification *)aNotification;
- (void) handleReachabilityDetectorDidUpdate:(NSNotification *)aNotification;

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAUser *user;
@end


@implementation WAUserInfoViewController

@synthesize monitoredHosts;
@synthesize managedObjectContext;
@synthesize user;

- (void) irConfigure {

  [super irConfigure];
  
  self.title = NSLocalizedString(@"SETTINGS_TITLE", @"Settings for User popover");
  
	self.tableViewStyle = UITableViewStyleGrouped;
  //	self.contentSizeForViewInPopover = (CGSize){ 320, 650 };
  self.persistsStateWhenViewWillDisappear = NO;
  self.restoresStateWhenViewDidAppear = NO;

}

- (void) viewDidLoad {

  [super viewDidLoad];
	
	self.tableView.sectionHeaderHeight = 56;
  
}

- (void) viewWillAppear:(BOOL)animated {

  [super viewWillAppear:animated];
	
  self.monitoredHosts = nil;
  [self.tableView reloadData];
	[self irBind:@"contentSizeForViewInPopover" toObject:self.tableView keyPath:@"contentSize" options:nil];
  
	NSError *fetchingError = nil;
  NSArray *fetchedUser = [self.managedObjectContext executeFetchRequest:[self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRUser" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
    [WARemoteInterface sharedInterface].userIdentifier, @"identifier",
  nil]] error:&fetchingError];
  
  if (!fetchedUser)
    NSLog(@"Fetching failed: %@", fetchingError);
  
  self.user = [fetchedUser lastObject];
	
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
  
  [self.tableView beginUpdates];
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kConnectivitySection] withRowAnimation:UITableViewRowAnimationFade];
  [self.tableView endUpdates];

}

- (void) handleReachabilityDetectorDidUpdate:(NSNotification *)aNotification {

  NSParameterAssert([NSThread isMainThread]);

  if (![self isViewLoaded])
    return;

#if 1
		
  [self.tableView beginUpdates];
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kConnectivitySection] withRowAnimation:UITableViewRowAnimationFade];
  [self.tableView endUpdates];

#else
	
  WAReachabilityDetector *targetDetector = aNotification.object;
  NSURL *updatedHost = targetDetector.hostURL;
  
  @try {
  
    NSUInteger displayIndexOfHost = [monitoredHosts indexOfObject:updatedHost]; //  USE OLD STUFF
    if (displayIndexOfHost == NSNotFound)
      return;
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:displayIndexOfHost inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];   

  } @catch (NSException *exception) {

    [self.tableView reloadData];
    
  }

#endif
  
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
  [monitoredHosts release];
  monitoredHosts = [newMonitoredHosts retain];
  [self didChangeValueForKey:@"monitoredHosts"];

}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

  return 3;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
  switch (section) {
			
    case 0:
      return 2;
			
		case kConnectivitySection:
			return [self.monitoredHosts count];
			
		case 2:
      return 3;
			
    default:
      return 0;
			
  };
	
}

- (CGFloat) tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section {

  return 48;
	
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	if (indexPath.section == 0)
	if (indexPath.row == 0)
		return 56;
	
	return tableView.rowHeight;

}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  if (section == 0)
    return NSLocalizedString(@"USER_INFO_ACCOUNT_SECTION_TITLE", @"Title in User Section");
  
	if (section == kConnectivitySection)
    return NSLocalizedString(@"ENDPOINT_CONNECTIVITY_STATUS_TITLE", @"Endpoint Status");
  
  if (section == 2)
    return NSLocalizedString(@"NOUN_STORAGE_QUOTA", @"Noun for storage quota.");
  return nil;

}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

	if (section == kConnectivitySection) {
	
		NSUInteger numberOfMonitoredHosts = [self.monitoredHosts count];

		if (numberOfMonitoredHosts == 0)
			return NSLocalizedString(@"ENDPOINT_REACHABILITY_STATUS_NO_ENDPOINTS_DESCRIPTION", @"Text to show when not even Cloud is there — a rare case");
		
		if (numberOfMonitoredHosts == 1)
			return NSLocalizedString(@"ENDPOINT_REACHABILITY_STATUS_CLOUD_ONLY_DESCRIPTION", @"Text to show when only Cloud is available");
		
		if ([[WARemoteInterface sharedInterface] areExpensiveOperationsAllowed])
			return NSLocalizedString(@"ENDPOINT_REACHABILITY_STATUS_CLOUD_AND_STATION_AVAILABLE_DESCRIPTION", @"Text to show when Cloud and Station are both available");
		
		return NSLocalizedString(@"ENDPOINT_REACHABILITY_STATUS_STATION_NOT_AVAILABLE_DESCRIPTION", @"Text to show when Cloud is available, but the Station is not responsive");

	}
	
	if (section == 2) {
		return NSLocalizedString(@"SHORT_LEGAL_DISCLAIMER", @"Production Disclaimer");
	}
	return nil;

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	__block UITableViewCell *cell = nil;
	NSString * const kValue1Identifier = @"Value1Cell";
	NSString * const kSubtitleCellIdentifier = @"SubtitleCell";
	
	UITableViewCell * (^createCell)(NSString *, UITableViewCellStyle) = ^ (NSString *anIdentifier, UITableViewCellStyle aStyle) {
		
		cell = [tableView dequeueReusableCellWithIdentifier:anIdentifier];
		if (!cell) {
			cell = [[[UITableViewCell alloc] initWithStyle:aStyle reuseIdentifier:anIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
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
				cell = createCell(kValue1Identifier, UITableViewCellStyleSubtitle);
				cell.textLabel.text = self.user.nickname;
				cell.detailTextLabel.text = self.user.email;
				break;
			}
			
			case 1: {
				cell = anyCell();
				cell.textLabel.text = NSLocalizedString(@"NOUN_CURRENT_DEVICE", @"This Device");
				cell.detailTextLabel.text = [UIDevice currentDevice].name;
				break;
			}
			
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
		
	} else if (indexPath.section == 2) {
		  
		cell = anyCell();
		
		NSDictionary *storageInfo = (NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:kWAUserStorageInfo];
		NSNumber *used = [storageInfo valueForKeyPath:@"waveface.usage.month_total_objects"];
		NSNumber *all = [storageInfo valueForKeyPath:@"waveface.quota.month_total_objects"];
				
		switch ([indexPath row]) {
			
			case 0: {
			
				cell.textLabel.text = NSLocalizedString(@"STORAGE_NUMBER_OF_ALLOTTED_OBJECTS_TITLE", nil);
				cell.detailTextLabel.text = ([all isEqualToNumber:[NSNumber numberWithInteger:-1]]) ?
					NSLocalizedString(@"STORAGE_QUOTA_UNLIMITED_TITLE", nil):
					[NSString stringWithFormat:@"%@", all];
				
				break;
				
			}
			
			case 1: {
			
				cell.textLabel.text = NSLocalizedString(@"STORAGE_NUMBER_OF_USED_OBJECTS_TITLE", nil);
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", used];
				
				break;
				
			}
			
			case 2: {
			
				NSUInteger (^dayOrdinality)(NSDate *) = ^ (NSDate *aDate) {
					return [[NSCalendar currentCalendar] ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:aDate];
				};
				
				NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[[storageInfo valueForKeyPath:@"waveface.interval.quota_interval_end"] doubleValue]];
				NSInteger daysLeft = dayOrdinality(endDate) - dayOrdinality([NSDate date]);
			
				cell.textLabel.text = NSLocalizedString(@"STORAGE_QUOTA_CYCLE_DAYS_LEFT", nil);
				cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"STORAGE_QUOTA_CYCLE_DAYS_LEFT_FORMAT_STRING", @"Number of days left in cycle"), daysLeft];
				
				break;
				
			}
				
			case 3: {
				cell.textLabel.text = NSLocalizedString(@"STORATE_QUOTA_INTERVAL_END_DATE", nil);
				cell.detailTextLabel.text = [[IRRelativeDateFormatter sharedFormatter] stringFromDate:
					[NSDate dateWithTimeIntervalSince1970:[[storageInfo valueForKeyPath:@"waveface.interval.quota_interval_end"] doubleValue]]
				];
				break;
			}
			
			default:
				break;
			
		}
		
	}
	
	NSParameterAssert(cell);
  return cell;

}

- (NSManagedObjectContext *) managedObjectContext {
  
  if (managedObjectContext)
    return managedObjectContext;
    
  managedObjectContext = [[[WADataStore defaultStore] defaultAutoUpdatedMOC] retain];
  return managedObjectContext;

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
  
  [super viewDidUnload];	
	[self irUnbind:@"contentSize"];
	
}

- (void) dealloc {

  [monitoredHosts release];
  [managedObjectContext release];
  
	[self irUnbind:@"contentSize"];
  
  [super dealloc];

}

@end
