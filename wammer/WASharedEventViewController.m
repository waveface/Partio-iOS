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
#import "WAGeoLocation.h"
#import <CoreLocation/CoreLocation.h>
#import "WADataStore.h"
#import "WAPartioNavigationController.h"
#import "NSDate+WAAdditions.h"
#import <QuartzCore/QuartzCore.h>

@interface WASharedEventViewController ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *eventFetchedResultsController;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, strong) WATransparentToolbar *toolbar;

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
  
  [self setTitle:NSLocalizedString(@"LABEL_SHARED_EVENTS", @"LABEL_SHARED_EVENTS")];
  
  UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setFrame:CGRectMake(0.f, 0.f, 105.f, 93.f)];
  [button setImage:[UIImage imageNamed:@"AddEvent"] forState:UIControlStateNormal];
  [button addTarget:self action:@selector(shareNewEventFromHighlight) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithCustomView:button];
  self.toolbar = [[WATransparentToolbar alloc] initWithFrame:CGRectMake(0.f, CGRectGetHeight(self.view.frame) - 170.f, 320.f, 170.f)];
  self.toolbar.items = @[flexibleSpace, addButton, flexibleSpace];
  [self.view addSubview:self.toolbar];
  
  [self.collectionView registerNib:[UINib nibWithNibName:@"WASharedEventViewCell" bundle:nil] forCellWithReuseIdentifier:kCellID];
  
  _objectChanges = [[NSMutableArray alloc] init];
  [self eventFetchedResultsController];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (![_eventFetchedResultsController.fetchedObjects count]) {
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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

  NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
  
  switch(type) {
      
    case NSFetchedResultsChangeInsert:
      change[@(type)] = newIndexPath;
      break;
      
    case NSFetchedResultsChangeDelete:
      change[@(type)] = indexPath;
      break;
      
    case NSFetchedResultsChangeUpdate:
      change[@(type)] = indexPath;
      break;
      
    case NSFetchedResultsChangeMove:
      change[@(type)] = @[indexPath, newIndexPath];
      break;
      
  }
  
  [self.objectChanges addObject:change];
  
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  //FIXME: update change fist

  dispatch_async(dispatch_get_main_queue(), ^{
    if ([self.objectChanges count]) {
      
      [self.collectionView performBatchUpdates:^{
        
        for (NSDictionary *change in self.objectChanges) {
          [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            
            switch (type) {
              case NSFetchedResultsChangeInsert:
                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                break;
                
              case NSFetchedResultsChangeDelete:
                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                break;
                
              case NSFetchedResultsChangeUpdate:
                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                break;
                
              case NSFetchedResultsChangeMove:
                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                break;
                
            }
            
          }];
        }
      }
                                    completion:nil];
    }
    
  });
  
  [self.objectChanges removeAllObjects];
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
  return [_eventFetchedResultsController.fetchedObjects count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  WASharedEventViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
  
  // Configure the cell...
  WAArticle *aArticle = [_eventFetchedResultsController objectAtIndexPath:indexPath];
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
  
  [cell.stickerNew setHidden:NO];
  [cell.photoNumber setText:[NSString stringWithFormat:@"%d", photoNumbers]];
  [cell.checkinNumber setText:[NSString stringWithFormat:@"%d", checkinNumbers]];
  [cell.peopleNumber setText:[NSString stringWithFormat:@"%d", pplNumber]];
  [cell.date setText:eventDate];
  [cell.location setText:location];
  
  [cell.infoView.layer layoutIfNeeded];
  
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
  return CGSizeMake(320.f, 140.f);
  
}

#pragma mark - toolbar

- (void)shareNewEventFromHighlight
{
  WAPartioNavigationController *phVC = [WAPhotoHighlightsViewController viewControllerWithNavigationControllerWrapped];
  [self presentViewController:phVC animated:YES completion:nil];
}

@end
