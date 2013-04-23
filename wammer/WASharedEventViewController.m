//
//  WAEventSharingViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASharedEventViewController.h"
#import "WASharedEventViewCell.h"
#import "WAPhotoHighlightsViewController.h"
#import "WAPhotoTimelineViewController.h"
#import "WATransparentToolbar.h"
#import "WANavigationController.h"
#import "WAGeoLocation.h"
#import <CoreLocation/CoreLocation.h>
#import "WADataStore.h"
#import "WAPartioNavigationBar.h"
#import "NSDate+WAAdditions.h"
#import <QuartzCore/QuartzCore.h>

@interface WASharedEventViewController ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *eventFetchedResultsController;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) WAPartioNavigationBar *navigationBar;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@end

static NSString *kCellID = @"EventCell";

@implementation WASharedEventViewController

- (NSManagedObjectContext *)managedObjectContext {
  if (_managedObjectContext)
    return _managedObjectContext;
  
  _managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return _managedObjectContext;
}

- (NSFetchedResultsController *)eventFetchedResultsController
{
  if (_eventFetchedResultsController) {
    return _eventFetchedResultsController;
  }
  
  NSManagedObjectContext *moc = self.managedObjectContext;
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WAArticle"];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
  [fetchRequest setSortDescriptors:@[sortDescriptor]];
  
  _eventFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                       managedObjectContext:moc
                                                                         sectionNameKeyPath:nil
                                                                                  cacheName:nil];
  _eventFetchedResultsController.delegate = self;
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event = TRUE AND eventType = %d AND hidden = FALSE", WAEventArticleSharedType];
  [_eventFetchedResultsController.fetchRequest setPredicate:predicate];
  
  NSError *Err;
  if (![_eventFetchedResultsController performFetch:&Err]) {
    NSLog(@"Fetch WAArticle failed: %@", Err);
  }
  
  return _eventFetchedResultsController;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.navigationController.navigationBarHidden = YES;
  [self.navigationItem setTitle:NSLocalizedString(@"LABEL_SHARED_EVENTS", @"LABEL_SHARED_EVENTS")];
  self.navigationBar = [[WAPartioNavigationBar alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), 44.f)];
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
  [self.view addSubview:self.navigationBar];
  
  [self.collectionView setFrame:CGRectMake(0.f,
                                           CGRectGetHeight(self.navigationBar.frame),
                                           CGRectGetHeight(self.view.frame),
                                           CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navigationBar.frame))];
    
  [self.collectionView registerNib:[UINib nibWithNibName:@"WASharedEventViewCell" bundle:nil] forCellWithReuseIdentifier:kCellID];
  
  _objectChanges = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (![self.eventFetchedResultsController.fetchedObjects count]) {
    [self shareNewEventFromHighlight:nil];
    
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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

  NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
  
  switch(type) {
      
    case NSFetchedResultsChangeInsert:
      NSLog(@"Insert, objectID: %@, indexPath: %@, newIndexPath: %@", [anObject objectID], indexPath, newIndexPath);
      change[@(type)] = newIndexPath;
      break;
      
    case NSFetchedResultsChangeDelete:
      NSLog(@"Delete, objectID: %@, indexPath: %@", [anObject objectID], indexPath);
      change[@(type)] = indexPath;
      break;
      
    case NSFetchedResultsChangeUpdate:
      NSLog(@"Update, objectID: %@, indexPath: %@", [anObject objectID], indexPath);
      change[@(type)] = indexPath;
      break;
      
    case NSFetchedResultsChangeMove:
      NSLog(@"Move, objectID: %@, indexPath: %@, newIndexPath: %@", [anObject objectID], indexPath, newIndexPath);
      change[@(type)] = @[indexPath, newIndexPath];
      break;
      
  }
  
  [self.objectChanges addObject:change];
  
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  //FIXME: update change fist
  
  __weak WASharedEventViewController *wSelf = self;
  if ([self.objectChanges count]) {
/* FIXME: Bugs here
    dispatch_async(dispatch_get_main_queue(), ^{
      
    [self.collectionView performBatchUpdates:^{
      
      for (NSDictionary *change in self.objectChanges) {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
          
          NSFetchedResultsChangeType type = [key unsignedIntegerValue];
          
          switch (type) {
            case NSFetchedResultsChangeInsert:
              [wSelf.collectionView insertItemsAtIndexPaths:@[obj]];
              break;
              
            case NSFetchedResultsChangeDelete:
              [wSelf.collectionView deleteItemsAtIndexPaths:@[obj]];
              break;
              
            case NSFetchedResultsChangeUpdate:
              [wSelf.collectionView reloadItemsAtIndexPaths:@[obj]];
              break;
              
            case NSFetchedResultsChangeMove:
              [wSelf.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
              break;
              
          }
          
        }];
      }
      
    } completion:^(BOOL finished) {
      
      [wSelf.objectChanges removeAllObjects];
      
    }];
    });
*/
    [self.collectionView reloadData];
    [wSelf.objectChanges removeAllObjects];
  }
  
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  // Return the number of sections.
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
//  return [self.eventFetchedResultsController.fetchedObjects count];
  return [[[self.eventFetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  WASharedEventViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
  
  // Configure the cell...
  WAArticle *aArticle = [self.eventFetchedResultsController objectAtIndexPath:indexPath];
  cell.imageView.image = nil;
  [aArticle irObserve:@"representingFile.thumbnailImage"
              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
              context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior){
               
                dispatch_async(dispatch_get_main_queue(), ^{
                  cell.imageView.image = (UIImage *)toValue;
                  cell.imageView.clipsToBounds = YES;
                });

              }];
  
  NSInteger pplNumber = [[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"people"] count];
  NSInteger photoNumbers = [[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"files"] count];
  
  static NSDateFormatter *sharedDateFormatter;
  sharedDateFormatter = [[NSDateFormatter alloc] init];
  [sharedDateFormatter setDateStyle:NSDateFormatterLongStyle];
  [sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
  
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
  NSInteger checkinNumbers = 0;
  if (Error) {
    NSLog(@"Failed to fetch checkins: %@", Error);
    
  } else {
    checkinNumbers = [checkins count];
    if (checkinNumbers) {
      location = [[checkins valueForKeyPath:@"name"] componentsJoinedByString:@", "];
      
    } else {
      location = @"Location";
      //location = [[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"location"] name];
      
    }
  }
  
  [cell.stickerNew setHidden:YES];
  [cell.photoNumber setText:[NSString stringWithFormat:@"%d", photoNumbers]];
  [cell.checkinNumber setText:[NSString stringWithFormat:@"%d", checkinNumbers]];
  [cell.peopleNumber setText:[NSString stringWithFormat:@"%d", pplNumber]];
  [cell.date setText:eventDate];
  [cell.location setText:location];
  
  return cell;

  
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  WAPhotoTimelineViewController *ptVC = [[WAPhotoTimelineViewController alloc] initWithArticleID:[[self.eventFetchedResultsController objectAtIndexPath:indexPath] objectID]];
  [self.navigationController pushViewController:ptVC animated:YES];
}

#pragma - conform to UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return CGSizeMake(CGRectGetWidth(collectionView.frame), 140.f);
  
}

#pragma mark - toolbar

- (IBAction)shareNewEventFromHighlight:(id)sender
{
  WANavigationController *phVC = [WAPhotoHighlightsViewController viewControllerWithNavigationControllerWrapped];
  [self presentViewController:phVC animated:YES completion:nil];
}

@end
