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


- (id) init {

  return [self initWithStyle:UITableViewStyleGrouped];

}

- (id) initWithStyle:(UITableViewStyle)style {
  
  self = [super initWithStyle:style];
  if (!self)
    return nil;
  
  [self updateDisplayTitleWithPotentialTitle:nil];
  
  self.contentSizeForViewInPopover = (CGSize){ 320, 416 };
  
  return self;
  
}

- (void) viewDidLoad {

  [super viewDidLoad];
  
  self.tableView.tableHeaderView = ((^ {
  
    UITableViewCell *cell = [self headerCell];
    UIView *returnedView = [[[UIView alloc] initWithFrame:cell.bounds] autorelease];
    [returnedView addSubview:cell];
    
    return returnedView;
    
  })());
  
  self.tableView.rowHeight = 54.0f;

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

  return 1;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  switch (section) {
  
    case 0:
      return [self.monitoredHosts count];
  
    default:
      return 0;
  
  };

}

- (CGFloat) tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)section {

  if (section == 0)
    return 48;
  
  return aTableView.sectionHeaderHeight;

}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  if (section == 0)
    return NSLocalizedString(@"WANounPluralEndpoints", @"Plural noun for remote endpoints");
  
  return nil;

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  NSString * const kIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
  if (!cell) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kIdentifier] autorelease];
  }
  
  if (indexPath.section == 0) {
    
    NSURL *hostURL = [self.monitoredHosts objectAtIndex:indexPath.row];
    cell.textLabel.text = [hostURL host];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)",
      NSLocalizedStringFromWAReachabilityState([[WARemoteInterface sharedInterface] reachabilityStateForHost:hostURL]),
      [hostURL absoluteString]
    ];
    
  }
  
  return cell;

}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {

  if (scrollView == self.tableView) {
  
    UIView *tableHeaderView = self.tableView.tableHeaderView;
    CGPoint contentOffset = self.tableView.contentOffset;
    
    self.tableView.tableHeaderView.center = (CGPoint) {
      contentOffset.x + 0.5f * CGRectGetWidth(tableHeaderView.bounds),
      contentOffset.y + 0.5f * CGRectGetHeight(tableHeaderView.bounds)
    };
    
     [tableHeaderView.superview bringSubviewToFront:tableHeaderView]; 
  
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

  NSError *fetchingError = nil;
  NSArray *fetchedUser = [self.managedObjectContext executeFetchRequest:[self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRUser" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
    [WARemoteInterface sharedInterface].userIdentifier, @"identifier",
  nil]] error:&fetchingError];
  
  if (!fetchedUser)
    NSLog(@"Fetching failed: %@", fetchingError);
  
  WAUser *user = [fetchedUser lastObject];
  self.headerCell.userNameLabel.text = user.nickname;
  self.headerCell.userEmailLabel.text = user.email;
  self.headerCell.avatarView.image = user.avatar;
  
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
