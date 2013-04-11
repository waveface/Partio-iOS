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
#import "WAGeoLocation.h"
#import <CoreLocation/CoreLocation.h>
#import "WADataStore.h"
#import "NSDate+WAAdditions.h"

@interface WASharedEventViewController ()

@property (nonatomic, strong) NSFetchedResultsController *eventFetchedResultsController;

@end

@implementation WASharedEventViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
    [self loadEvents];
  }
  
  return self;
}

- (NSArray *)loadEvents
{
  NSManagedObjectContext *moc = [[WADataStore defaultStore] autoUpdatingMOC];
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAArticle"];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
  [fetchRequest setSortDescriptors:@[sortDescriptor]];
  self.eventFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event = TRUE AND eventType = %d AND hidden = FALSE", WAEventArticleSharedType];
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
  
  if (![self.eventFetchedResultsController.fetchedObjects count]) {
    [self shareNewEventFromHighlight];
    
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
  [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
  
  switch(type) {
    case NSFetchedResultsChangeInsert:
      [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                    withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeDelete:
      [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                    withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
  
  UITableView *tableView = self.tableView;
  
  switch(type) {
      
    case NSFetchedResultsChangeInsert:
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeDelete:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeUpdate:
      //TODO: update info: photo number, checkin number, date, location
      break;
      
    case NSFetchedResultsChangeMove:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                       withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView endUpdates];
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
  return [self.eventFetchedResultsController.fetchedObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  // Configure the cell...
  cell.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
  cell.backgroundView.clipsToBounds = YES;

  UIImage *backgroundImage = [[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKeyPath:@"representingFile"] thumbnailImage];
  cell.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
  
  NSInteger fileNumbers = [[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"files"] count];
  NSString *photoNumbers = [NSString stringWithFormat:(fileNumbers == 1)?
                            NSLocalizedString(@"EVENT_ONE_PHOTO_NUMBER_LABEL", @"EVENT_ONE_PHOTO_NUMBER_LABEL"):
                            NSLocalizedString(@"EVENT_PHOTO_NUMBER_LABEL", @"EVENT_PHOTO_NUMBER_LABEL"),
                            fileNumbers];
  static NSDateFormatter *sharedDateFormatter;
  sharedDateFormatter = [[NSDateFormatter alloc] init];
  [sharedDateFormatter setDateFormat:@"yyyy MM dd"];
  NSString *eventDate = [sharedDateFormatter stringFromDate:[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"eventStartDate"]];
  
  NSString *location = @"";
  NSArray *checkins = [[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKeyPath:@"checkins"];
  if ([checkins count]) {
    location = [[checkins valueForKeyPath:@"name"] componentsJoinedByString:@", "];
    
  }
  
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
  WAPhotoTimelineViewController *ptVC = [[WAPhotoTimelineViewController alloc] initWithArticleID:[[self.eventFetchedResultsController objectAtIndexPath:indexPath] objectID]];
  [self.navigationController pushViewController:ptVC animated:YES];
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
