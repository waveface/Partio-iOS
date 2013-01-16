//
//  WAConnectionStatusViewController.m
//  wammer
//
//  Created by kchiu on 13/1/9.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAConnectionStatusViewController.h"
#import "WADataStore.h"
#import "WARemoteInterface.h"
#import "WAStation.h"

static NSString * const kWAHostCellReuseIdentifier = @"WAHostCellReuseIdentifier";

@interface WAConnectionStatusViewController ()

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSArray *hosts;

@end

@implementation WAConnectionStatusViewController

- (void)awakeFromNib {

  self.hosts = [NSArray array];
  NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"WAStation" inManagedObjectContext:context];
  [request setEntity:entity];
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
  [request setSortDescriptors:@[sortDescriptor]];
  self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
  NSError *error = nil;
  if ([self.fetchedResultsController performFetch:&error]) {
    self.hosts = self.fetchedResultsController.fetchedObjects;
  } else {
    NSLog(@"Unable to fetch stations, error:%@", error);
  }

}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  if (isPad())
	return UIInterfaceOrientationMaskAll;
  else
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

  return 1;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  if ([self.hosts count]) {
    return [self.hosts count] + 1;
  } else {
    return 2;
  }

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  return NSLocalizedString(@"NOW_CONNECTING_HEADER", @"Section header in connection status view controller");

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kWAHostCellReuseIdentifier];
  
  cell.textLabel.text = @"";
  cell.accessoryType = UITableViewCellAccessoryNone;
  
  WARemoteInterface *ri = [WARemoteInterface sharedInterface];
  if ([indexPath row] == 0) {
    cell.textLabel.text = NSLocalizedString(@"CLOUD_NAME", @"AOStream Cloud Name");
    if ([ri hasReachableCloud] && ![ri hasReachableStation]) {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
  } else {
    if ([self.hosts count]) {
      WAStation *station = self.hosts[[indexPath row]-1];
      cell.textLabel.text = station.name;
      if ([ri hasReachableStation] && [[ri.monitoredHosts[0] identifier] isEqualToString:station.identifier]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
      }
    } else {
      cell.textLabel.text = NSLocalizedString(@"NO_STATION_INSTALLED", @"Cell title in connection status view controller");
    }
  }
  
  return cell;

}

@end
