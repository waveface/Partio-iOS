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
-(NSInteger)daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate
{
     NSInteger startDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:startDate];
     NSInteger endDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:endDate];
     return endDay-startDay;
}
-(NSInteger)daysFromNow:(NSDate *) someDate
{
     NSInteger startDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:[NSDate date]];
     NSInteger endDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:someDate];
     return endDay-startDay;
}
@end

@interface WAUserInfoViewController ()

@property (nonatomic, readwrite, retain) WAUserInfoHeaderCell *headerCell;
@property (nonatomic, readwrite, retain) NSArray *monitoredHosts;

- (void) handleReachableHostsDidChange:(NSNotification *)aNotification;
- (void) handleReachabilityDetectorDidUpdate:(NSNotification *)aNotification;

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

- (void) updateDisplayTitleWithPotentialTitle:(NSString *)aTitleOrNil;

@end


@implementation WAUserInfoViewController

@synthesize headerCell;
@synthesize monitoredHosts;
@synthesize managedObjectContext;


- (void) irConfigure {

  [super irConfigure];
  
  [self updateDisplayTitleWithPotentialTitle:nil];
  
	self.tableViewStyle = UITableViewStyleGrouped;
  self.contentSizeForViewInPopover = (CGSize){ 320, 500 };
  self.persistsStateWhenViewWillDisappear = NO;
  self.restoresStateWhenViewDidAppear = NO;
	self.title = NSLocalizedString(@"WASettings", nil);

}

- (void) viewDidLoad {

  [super viewDidLoad];
	
	UILabel *productDisclaimer = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 52)] autorelease];
	productDisclaimer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	productDisclaimer.backgroundColor = [UIColor clearColor];
	productDisclaimer.text = NSLocalizedString(@"WAProductDisclaimer", nil);
	productDisclaimer.textColor = [UIColor grayColor];
	productDisclaimer.textAlignment = UITextAlignmentCenter;
	productDisclaimer.numberOfLines = 2;
	productDisclaimer.shadowColor = [UIColor whiteColor];
	productDisclaimer.shadowOffset = CGSizeMake(1, 1);
		
	self.tableView.tableFooterView = productDisclaimer;
	
	  
//  __block UITableView *nrTV = self.tableView;
//  
//  self.tableView.tableHeaderView = ((^ {
//  
//    UITableViewCell *cell = [self headerCell];
//		cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//		
//    UIView *returnedView = [[[UIView alloc] initWithFrame:cell.bounds] autorelease];
//		returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//		
//    [returnedView addSubview:cell];
//    
//    return returnedView;
//    
//  })());
//	
//	
//	self.tableView.scrollIndicatorInsets = (UIEdgeInsets){
//		CGRectGetHeight(self.tableView.tableHeaderView.bounds),		
//		0, 
//		0, 
//		0
//	};
//  
//  self.tableView.onLayoutSubviews = ^ {
//  
//    UIView *tableHeaderView = nrTV.tableHeaderView;
//    CGPoint contentOffset = nrTV.contentOffset;
//    
//    nrTV.tableHeaderView.center = (CGPoint) {
//      contentOffset.x + 0.5f * CGRectGetWidth(tableHeaderView.bounds),
//      contentOffset.y + 0.5f * CGRectGetHeight(tableHeaderView.bounds)
//    };
//    
//    if ([tableHeaderView.superview.subviews lastObject] != tableHeaderView)
//      [tableHeaderView.superview bringSubviewToFront:tableHeaderView]; 
//  
//  };
//
}

- (void) viewWillAppear:(BOOL)animated {

  [super viewWillAppear:animated];
  
  self.monitoredHosts = nil;
  [self.tableView reloadData];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReachableHostsDidChange:) name:kWARemoteInterfaceReachableHostsDidChangeNotification object:nil];  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReachabilityDetectorDidUpdate:) name:kWAReachabilityDetectorDidUpdateStatusNotification object:nil];
  
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

  return 2;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  switch (section) {
  
    case 0:
      return 3; //[self.monitoredHosts count];
			
		case 1:
			return 4;
  
    default:
      return 0;
  
  };

}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	if (indexPath.section != 0)
		return tableView.rowHeight;
	
	return 56;

}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  if (section == 0)
    return NSLocalizedString(@"USER_ACCOUNT_HEADER", nil);
  
	if (section == 1)
    return NSLocalizedString(@"SYSTEM_STATUS_HEADER", nil);
  
  return nil;

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	NSString * const kAccountInfoIdentifier = @"AccountInfo";
	UITableViewCell *cell = nil;

	cell = [tableView dequeueReusableCellWithIdentifier:kAccountInfoIdentifier];
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kAccountInfoIdentifier] autorelease];
	}

  if (indexPath.section == 0) {
		NSError *fetchingError = nil;
		NSArray *fetchedUser = [self.managedObjectContext executeFetchRequest:[self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRUser" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
    [WARemoteInterface sharedInterface].userIdentifier, @"identifier",
  nil]] error:&fetchingError];
  
		if (!fetchedUser)
			NSLog(@"Fetching failed: %@", fetchingError);
		
		WAUser *user = [fetchedUser lastObject];
		
		switch ([indexPath row]) {
			case 0: {
				cell.textLabel.text = NSLocalizedString(@"WAUserName", nil);
				cell.detailTextLabel.text = user.nickname;
				break;
			}
			
			case 1: {
				cell.textLabel.text = NSLocalizedString(@"WAUserEmail", nil);
				cell.detailTextLabel.text = user.email;
				break;
			}
			
			case 2: {
				cell.textLabel.text = NSLocalizedString(@"WADeviceName", nil);
				cell.detailTextLabel.text = [[UIDevice currentDevice] name];
				break;
			}
			
			default:
				break;
			
		}  
		
  } else if (indexPath.section == 1) {
		NSDictionary *storageInfo = (NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:kWAUserStorageInfo];
		
		switch ([indexPath row]) {
			case 0: {
				cell.textLabel.text = NSLocalizedString(@"WAConnectToCloudOrStation", nil);
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				break;
			}

			case 1: {
				cell.textLabel.text = NSLocalizedString(@"WAStorageQuotaAllObjects", nil);
				cell.detailTextLabel.text = ((^{
						NSNumber *quota=[storageInfo valueForKeyPath:@"waveface.quota.month_total_objects"];
						if ( [quota intValue] == -1 ) 
							return NSLocalizedString(@"WAInfinity", @"Unlimited storage size. This should be rare.");
						return [quota stringValue];
					}()));
				break;
			}
			
			case 2: {
				cell.textLabel.text = NSLocalizedString(@"WAStorageObjectsUsed", nil);
				cell.detailTextLabel.text = [[storageInfo valueForKeyPath:@"waveface.usage.month_total_objects"] stringValue];
				break;
			}
			
			
			case 3: {
				NSDate *expireDate = [NSDate dateWithTimeIntervalSince1970:
					[[storageInfo valueForKeyPath:@"waveface.interval.quota_interval_end"] doubleValue]];
				
				cell.textLabel.text = NSLocalizedString(@"WAStorageQuotaInterval", nil);
				cell.detailTextLabel.text =  [NSString stringWithFormat:
					NSLocalizedString(@"%d days", @"days before expire"), 
					[[NSCalendar currentCalendar] daysFromNow:expireDate]
					];
				break;
			}
				
			case 4: {
				cell.textLabel.text = NSLocalizedString(@"WAStorageQuotaAllImages", nil);
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ / %@",
					[storageInfo valueForKeyPath:@"waveface.usage.month_image_objects"],
					((^{
						NSNumber *quota=[storageInfo valueForKeyPath:@"waveface.quota.month_image_objects"];
						if ( [quota intValue] == -1 ) 
							return NSLocalizedString(@"WAInfinity", @"Unlimited storage size. This should be rare.");
						return [quota stringValue];
					}()))
				];
				break;
			}
			
			case 5: {
				cell.textLabel.text = NSLocalizedString(@"WAStorageQuotaIntervalEndDate", nil);
				cell.detailTextLabel.text = [[NSDate dateWithTimeIntervalSince1970:[[storageInfo valueForKeyPath:@"waveface.interval.quota_interval_end"] doubleValue]] stringValue];
				NSLog(@"%@", [[storageInfo valueForKeyPath:@"waveface.interval.quota_interval_end"] doubleValue]);
//				  [[IRRelativeDateFormatter sharedFormatter] stringFromDate:
//					[NSDate dateWithTimeIntervalSince1970:[[storageInfo valueForKeyPath:@"waveface.interval.quota_interval_end"] doubleValue]]
//				];
				break;
			}
			
			default:
				break;
		}  

	
		return cell;
		NSURL *hostURL = [self.monitoredHosts objectAtIndex:indexPath.row];
    cell.textLabel.text = [hostURL host];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)",
      NSLocalizedStringFromWAReachabilityState([[WARemoteInterface sharedInterface] reachabilityStateForHost:hostURL]),
      [hostURL absoluteString]
    ];

	}
	
  return cell;

}

- (void) tableView:(UITableView *)aTV didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

//  if (indexPath.section == 0) {
//  
//    NSURL *hostURL = [self.monitoredHosts objectAtIndex:indexPath.row];
//    WAReachabilityDetector *detector = [[WARemoteInterface sharedInterface] reachabilityDetectorForHost:hostURL];
//    
//    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Diagnostics" message:[detector description] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
//    
//    [alertView show];
//    
//    [aTV deselectRowAtIndexPath:indexPath animated:YES];
//  
//  }

}





- (NSManagedObjectContext *) managedObjectContext {
  
  if (managedObjectContext)
    return managedObjectContext;
    
  managedObjectContext = [[[WADataStore defaultStore] defaultAutoUpdatedMOC] retain];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextObjectsDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
  
  return managedObjectContext;

}

- (void) handleManagedObjectContextObjectsDidChange:(NSNotification *)aNotification {

  NSError *fetchingError = nil;
  NSArray *fetchedUser = [self.managedObjectContext executeFetchRequest:[self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRUser" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
    [WARemoteInterface sharedInterface].userIdentifier, @"identifier",
  nil]] error:&fetchingError];
  
  if (!fetchedUser)
    NSLog(@"Fetching failed: %@", fetchingError);
  
  WAUser *user = [fetchedUser lastObject];
	NSIndexPath *userPath = [NSIndexPath indexPathForRow:0 inSection:0];
  [self.tableView cellForRowAtIndexPath:userPath].textLabel.text = user.nickname;
	userPath = [NSIndexPath indexPathForRow:1 inSection:0];
	[self.tableView cellForRowAtIndexPath:userPath].textLabel.text = user.email;
	self.headerCell.userNameLabel.text = user.nickname;
  self.headerCell.userEmailLabel.text = user.email;
  
  [self updateDisplayTitleWithPotentialTitle:user.nickname];

}

- (WAUserInfoHeaderCell *) headerCell {

  if (headerCell)
    return headerCell;

  headerCell = [[WAUserInfoHeaderCell cellFromNib] retain];
  [self handleManagedObjectContextObjectsDidChange:nil];
  
  return headerCell;

}





- (void) updateDisplayTitleWithPotentialTitle:(NSString *)aTitleOrNil {

  if (aTitleOrNil) {
    self.title = aTitleOrNil;
  } else {
    self.title = NSLocalizedString(@"WAUserInformationTitle", @"Title for user information");
  }

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  
  return YES;
  
}

- (void) viewDidUnload {

  self.headerCell = nil;
  
  [super viewDidUnload];

}

- (void) dealloc {

  [headerCell release];
  [monitoredHosts release];
  [managedObjectContext release];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [super dealloc];

}

@end
