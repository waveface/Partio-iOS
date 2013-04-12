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

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
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

- (NSManagedObjectContext*)managedObjectContext {
  if (_managedObjectContext)
    return _managedObjectContext;
  
  _managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return _managedObjectContext;
}

- (NSArray *)loadEvents
{
  NSManagedObjectContext *moc = self.managedObjectContext;
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAArticle"];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
  [fetchRequest setSortDescriptors:@[sortDescriptor]];
  
  self.eventFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                           managedObjectContext:moc
                                                                             sectionNameKeyPath:nil
                                                                                      cacheName:nil];
  self.eventFetchedResultsController.delegate = self;
  
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
  
  [self.navigationController setTitle:NSLocalizedString(@"LABEL_SHARED_EVENTS", @"LABEL_SHARED_EVENTS")];
  
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
    
  } else {
    [self.tableView reloadData];
  }
  
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

//FIXME: don't autorotate
- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
  [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
  
  UITableView *tableView = self.tableView;
  
  switch(type) {
      
    case NSFetchedResultsChangeInsert:
      [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeUpdate:
      [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  
  // Configure the cell...
  WAArticle *aArticle = [self.eventFetchedResultsController objectAtIndexPath:indexPath];
  [aArticle irObserve:@"representingFile.thumbnailImage"
              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
              context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior){
                dispatch_async(dispatch_get_main_queue(), ^{
                  cell.backgroundView = [[UIImageView alloc] initWithImage:(UIImage *)toValue];
                  cell.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
                  cell.backgroundView.clipsToBounds = YES;

                });                
              }];
  
  CAGradientLayer *gradientLayer = [CAGradientLayer layer];
  gradientLayer.frame = (CGRect){CGPointZero, cell.backgroundView.frame.size};
  gradientLayer.colors = @[(id)[[UIColor colorWithWhite:0.f alpha:0.4] CGColor], (id)[[UIColor colorWithWhite:0.f alpha:1.f] CGColor]];
  [cell.backgroundView.layer insertSublayer:gradientLayer above:nil];
  
  NSInteger fileNumbers = [[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"files"] count];
  NSString *photoNumbers = [NSString stringWithFormat:(fileNumbers == 1)?
                            NSLocalizedString(@"EVENT_ONE_PHOTO_NUMBER_LABEL", @"EVENT_ONE_PHOTO_NUMBER_LABEL"):
                            NSLocalizedString(@"EVENT_PHOTO_NUMBER_LABEL", @"EVENT_PHOTO_NUMBER_LABEL"),
                            fileNumbers];
  static NSDateFormatter *sharedDateFormatter;
  sharedDateFormatter = [[NSDateFormatter alloc] init];
  [sharedDateFormatter setDateFormat:@"yyyy MM dd"];
  NSDate *eDate = [[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"creationDate"];
  NSString *eventDate = [sharedDateFormatter stringFromDate:eDate];
  
  NSString *location = @"";
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WACheckin"];
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"createDate" ascending:NO];
  fetchRequest.sortDescriptors = @[sortDescriptor];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createDate = %@", eDate];
  fetchRequest.predicate = predicate;
  
  NSError *Error;
  NSArray *checkins = [self.managedObjectContext executeFetchRequest:fetchRequest error:&Error];
  if (Error) {
    NSLog(@"Failed to fetch checkins: %@", Error);
    
  } else {
    if ([checkins count]) {
      location = [[checkins valueForKeyPath:@"name"] componentsJoinedByString:@", "];
      
    } else {
      location = @"Location";
      
    }
    
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

#pragma mark - toolbar

- (void)shareNewEventFromHighlight
{
  WAPhotoHighlightsViewController *phVC = [[WAPhotoHighlightsViewController alloc] init];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:phVC];
  [self presentViewController:nav animated:YES completion:nil];
}

@end
