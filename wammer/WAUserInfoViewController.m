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

@implementation NSCalendar (MySpecialCalculations)
-(NSInteger)daysFromDate:(NSDate *) endDate
{
	NSDate *startDate = [NSDate date];
     NSInteger startDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:startDate];
     NSInteger endDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:endDate];
     return endDay-startDay;
}
@end

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
  
  self.title = NSLocalizedString(@"USER_SETTINGS", @"Settings for User popover");
  
	self.tableViewStyle = UITableViewStyleGrouped;
  self.contentSizeForViewInPopover = (CGSize){ 320, 416 };
  self.persistsStateWhenViewWillDisappear = NO;
  self.restoresStateWhenViewDidAppear = NO;

}

- (void) viewDidLoad {

  [super viewDidLoad];
  
}

- (void) viewWillAppear:(BOOL)animated {

  [super viewWillAppear:animated];
  
  self.monitoredHosts = nil;
  [self.tableView reloadData];
  
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
		return NSLocalizedString(@"WAProperNounWFCloud", @"Short label for the Cloud");

	return NSLocalizedString(@"WAProperNounWFStation", @"Short label for a particular Station");

}

- (void) handleReachableHostsDidChange:(NSNotification *)aNotification {

  NSParameterAssert([NSThread isMainThread]);
  
  self.monitoredHosts = ((WARemoteInterface *)aNotification.object).monitoredHosts;
  
  if (![self isViewLoaded])
    return;
  
  [self.tableView beginUpdates];
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
  [self.tableView endUpdates];

}

- (void) handleReachabilityDetectorDidUpdate:(NSNotification *)aNotification {

  NSParameterAssert([NSThread isMainThread]);

  if (![self isViewLoaded])
    return;

#if 1
		
  [self.tableView beginUpdates];
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
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

- (void) viewWillDisappear:(BOOL)animated {

  [super viewWillDisappear:animated];

  [[NSNotificationCenter defaultCenter] removeObserver:self]; //  crazy

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
      return 3;
			
		case 1:
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

	if (indexPath.section != 0)
		return tableView.rowHeight;
	
	return 56;

}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  if (section == 0)
    return NSLocalizedString(@"USER_SECTION_TITLE", @"Title in User Section");
  
	if (section == 1)
    return NSLocalizedString(@"CONNECTIVITY_STATUS", @"Endpoint Status");
  
  if (section == 2)
    return NSLocalizedString(@"STORAGE_QUOTA_STATUS", @"Noun for storage quota.");
  return nil;

}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

	if (section == 1) {
	
		NSUInteger numberOfMonitoredHosts = [self.monitoredHosts count];

		if (numberOfMonitoredHosts == 0)
			return NSLocalizedString(@"WAEndpointReachabilityStatusNoEndpointsDescription", @"Text to show when not even Cloud is there — a rare case");
		
		if (numberOfMonitoredHosts == 1)
			return NSLocalizedString(@"WAEndpointReachabilityStatusCloudOnlyDescription", @"Text to show when only Cloud is available");
		
		if ([[WARemoteInterface sharedInterface] areExpensiveOperationsAllowed])
			return NSLocalizedString(@"WAEndpointReachabilityStatusCloudAndStationAvailableDescription", @"Text to show when Cloud and Station are both available");
		
		return NSLocalizedString(@"WAEndpointReachabilityStatusStationNotAvailableDescription", @"Text to show when Cloud is available, but the Station is not responsive");

	}
	
	return nil;

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = nil;
	NSString * const kCellIdentifier = @"SettingsCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
		if (!cell) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
  if (indexPath.section == 0) {
		switch ([indexPath row]) {
			case 0:
				cell.textLabel.text = NSLocalizedString(@"USER_NAME", @"user nickname");
				cell.detailTextLabel.text = user.nickname;
				break;
			case 1:
				cell.textLabel.text = NSLocalizedString(@"USER_EMAIL", @"email");
				cell.detailTextLabel.text = user.email;
				break;
			case 2:
				cell.textLabel.text = NSLocalizedString(@"USER_DEVICE", @"This Device");
				cell.detailTextLabel.text = [[UIDevice currentDevice]name];
				break;
				
			default:
				break;
		}
	} else if (indexPath.section == 1) {
		if([self.monitoredHosts count] > 0) {
			NSURL *hostURL = [self.monitoredHosts objectAtIndex:indexPath.row];
			
			cell.textLabel.text = [self titleForMonitoredHost:hostURL];
			cell.detailTextLabel.text = NSLocalizedStringFromWAReachabilityState([[WARemoteInterface sharedInterface] reachabilityStateForHost:hostURL]);
		}
		
  } else if (indexPath.section == 2) {
		  
		NSDictionary *storageInfo = (NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:kWAUserStorageInfo];
		NSNumber *used = [storageInfo valueForKeyPath:@"waveface.usage.month_total_objects"];
		NSNumber *all = [storageInfo valueForKeyPath:@"waveface.quota.month_total_objects"];
				
		switch ([indexPath row]) {
			
			case 0: {
				cell.textLabel.text = NSLocalizedString(@"STORAGE_QUOTA_ALL_OBJECTS", nil);
				cell.detailTextLabel.text = ([all isEqualToNumber:[NSNumber numberWithInteger:-1]]) ?
					NSLocalizedString(@"UNLIMITED_QUOTA", nil):
					[NSString stringWithFormat:@"%@", all];
				
				break;
				
			}
			
			case 1: {
				cell.textLabel.text = NSLocalizedString(@"STORAGE_USED_ALL_OBJECTS", nil);
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", used];
				
				break;
				
			}
			
			case 2: {
				NSCalendar *calendar = [NSCalendar currentCalendar];
				NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:[[storageInfo valueForKeyPath:@"waveface.interval.quota_interval_end"] doubleValue]];
				NSInteger days = [calendar daysFromDate:endDate];
				cell.textLabel.text = NSLocalizedString(@"DAYS_LEFT_IN_CYCLE", nil);
				cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DAYS_LATER", @"Number of days left in cycle"), days];
				break;
			}
				
			case 3: {
				cell.textLabel.text = NSLocalizedString(@"WAStorageQuotaIntervalEndDate", nil);
				cell.detailTextLabel.text = [[IRRelativeDateFormatter sharedFormatter] stringFromDate:
					[NSDate dateWithTimeIntervalSince1970:[[storageInfo valueForKeyPath:@"waveface.interval.quota_interval_end"] doubleValue]]
				];
				break;
			}
			
			default:
				break;
			
		}
		
	}
	
  return cell;

}

- (void) tableView:(UITableView *)aTV didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.section == 0) {
	
		if (WAAdvancedFeaturesEnabled()) {
  
			NSURL *hostURL = [self.monitoredHosts objectAtIndex:indexPath.row];
			WAReachabilityDetector *detector = [[WARemoteInterface sharedInterface] reachabilityDetectorForHost:hostURL];
			
			UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Diagnostics" message:[detector description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			
			[alertView show];
			
			[aTV deselectRowAtIndexPath:indexPath animated:YES];
		
		}
  
  }

}

- (NSManagedObjectContext *) managedObjectContext {
  
  if (managedObjectContext)
    return managedObjectContext;
    
  managedObjectContext = [[[WADataStore defaultStore] defaultAutoUpdatedMOC] retain];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextObjectsDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
  
  return managedObjectContext;

}

- (void) handleManagedObjectContextObjectsDidChange:(NSNotification *)aNotification {


//  self.headerCell.userNameLabel.text = user.nickname;
//  self.headerCell.userEmailLabel.text = user.email;
//  self.headerCell.avatarView.image = user.avatar;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  
  return YES;
  
}

- (void) viewDidUnload {
  
  [super viewDidUnload];

}

- (void) dealloc {

  [monitoredHosts release];
  [managedObjectContext release];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];

}

@end
