//
//  WAEventSharingViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASharedEventViewController.h"
#import "WAPhotoHighlightsViewController.h"
#import "WAPhotoTimelineViewController.h"
#import "WALocation.h"
#import <CoreLocation/CoreLocation.h>
#import "WADataStore.h"
#import "NSDate+WAAdditions.h"

@interface WASharedEventViewController ()

@property (nonatomic, strong) NSFetchedResultsController *eventFetchedResultsController;
@property (nonatomic, strong) NSMutableArray *events;

@end

@implementation WASharedEventViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
    self.events = [[NSMutableArray alloc] init];
  }
  self.events = [[self loadEventsFrom:[NSDate date] toPreviousDays:100] copy];
  
  return self;
}

- (NSArray *)loadEventsFrom:(NSDate *)aDate toPreviousDays:(NSInteger)days
{
  NSManagedObjectContext *moc = [[WADataStore defaultStore] autoUpdatingMOC];
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAArticle"];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"eventStartDate" ascending:NO];
  [fetchRequest setSortDescriptors:@[sortDescriptor]];
  self.eventFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventStartDate >= %@ AND eventStartDate <= %@ AND event = TRUE AND hidden = FALSE AND files.@count > 0", [aDate dateOfPreviousNumOfDays:days], aDate];
  [self.eventFetchedResultsController.fetchRequest setPredicate:predicate];
  
  NSError *Err;
  if (![self.eventFetchedResultsController performFetch:&Err]) {
    NSLog(@"Fetch WAArticle failed: %@", Err);
  }
  
  return self.eventFetchedResultsController.fetchedObjects;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.navigationController setToolbarHidden:NO];
  UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(shareNewEventFromHighlight)];
  self.toolbarItems = @[flexibleSpace, addButton, flexibleSpace];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (![self.events count]) {
    [self shareNewEventFromHighlight];
    
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  return [self.events count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  // Configure the cell...
  cell.backgroundView = [[UIImageView alloc] initWithImage:[[self.events[indexPath.row] representingFile] thumbnailImage]];
  cell.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
  cell.backgroundView.clipsToBounds = YES;
  NSString *photoNumbers = [NSString stringWithFormat:([[self.events[indexPath.row] files] count] == 1)?
                            NSLocalizedString(@"EVENT_ONE_PHOTO_NUMBER_LABEL", @"EVENT_ONE_PHOTO_NUMBER_LABEL"):
                            NSLocalizedString(@"EVENT_PHOTO_NUMBER_LABEL", @"EVENT_PHOTO_NUMBER_LABEL"),
                            [[self.events[indexPath.row] files] count]];
  static NSDateFormatter *sharedDateFormatter;
  sharedDateFormatter = [[NSDateFormatter alloc] init];
  [sharedDateFormatter setDateFormat:@"yyyy MM dd"];
  NSString *eventDate = [sharedDateFormatter stringFromDate:[self.events[indexPath.row] eventStartDate]];
  NSString *location = [self.events[indexPath.row] description];
  cell.textLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@", photoNumbers, eventDate, location];
  [cell.textLabel setNumberOfLines:0];
  [cell.textLabel setBackgroundColor:[UIColor clearColor]];
  [cell.textLabel setTextColor:[UIColor whiteColor]];
  
  return cell;

  
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
//  __weak WASharedEventViewController *wSelf = self;
//  WAPhotoTimelineViewController *ptVC = [[WAPhotoTimelineViewController alloc] initWithArticle:[self.events[indexPath.row] objectID]];
//  WANavigationController *nav = [[WANavigationController alloc] initWithRootViewController:ptVC];
//  [wSelf presentViewController:nav animated:YES completion:nil];
}

#pragma - toolbar

- (void)shareNewEventFromHighlight
{
  __weak WASharedEventViewController *wSelf = self;
  WAPhotoHighlightsViewController *phVC = [[WAPhotoHighlightsViewController alloc] init];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:phVC];
  [self presentViewController:nav animated:YES completion:nil];
}

@end
