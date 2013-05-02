//
//  WAEventSharingViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASharedEventViewController.h"
#import "WASharedEventViewCell.h"
#import "WADayPhotoPickerViewController.h"
#import "WAPhotoTimelineViewController.h"
#import "WANavigationController.h"
#import "WAGeoLocation.h"
#import "WADefines.h"
#import <CoreLocation/CoreLocation.h>
#import "WADataStore.h"
#import "WAPartioNavigationBar.h"
#import "NSDate+WAAdditions.h"
#import <SMCalloutView/SMCalloutView.h>
#import <BlocksKit/BlocksKit.h>
#import <QuartzCore/QuartzCore.h>

@interface WASharedEventViewController ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *eventFetchedResultsController;
@property (nonatomic, strong) NSMutableArray *objectChanges;
@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIButton *creationButton;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) SMCalloutView *shareInstructionView;

@end

static NSString * const kCellID = @"EventCell";
static NSString * const kWASharedEventViewController_CoachMarks = @"kWASharedEventViewController_CoachMarks";

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
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCoreDataReinitialization:) name:kWACoreDataReinitialization object:nil];
  
  [self.navigationItem setTitle:NSLocalizedString(@"LABEL_SHARED_EVENTS", @"LABEL_SHARED_EVENTS")];
  [self.navigationItem setHidesBackButton:YES];
  [self.navigationController setNavigationBarHidden:YES];
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];

  
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
  
  BOOL coachmarkShown = [[NSUserDefaults standardUserDefaults] boolForKey:kWASharedEventViewController_CoachMarks];
  if (!coachmarkShown) {
    __weak WASharedEventViewController *wSelf = self;
    if (!self.shareInstructionView) {
      self.shareInstructionView = [SMCalloutView new];
      self.shareInstructionView.title = NSLocalizedString(@"INSTRUCTION_IN_EVENTLIST_CREATE_BUTTON", @"Instruction shown above the create button in the event list view.");
      [self.shareInstructionView presentCalloutFromRect:CGRectMake(self.creationButton.frame.origin.x +self.creationButton.frame.size.width/2, self.creationButton.frame.origin.y, 1, 1) inView:self.view constrainedToView:self.view permittedArrowDirections:SMCalloutArrowDirectionDown animated:YES];
      
      self.tapGesture = [[UITapGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (wSelf.shareInstructionView) {
          [wSelf.shareInstructionView dismissCalloutAnimated:YES];
          wSelf.shareInstructionView = nil;
        }
        [wSelf.view removeGestureRecognizer:wSelf.tapGesture];
        wSelf.tapGesture = nil;
      }];
      [self.view addGestureRecognizer:self.tapGesture];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWASharedEventViewController_CoachMarks];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void) dealloc {
  if (self.tapGesture)
    [self.view removeGestureRecognizer:self.tapGesture];
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (void) handleCoreDataReinitialization:(id)sender {
  
  _managedObjectContext = nil;
  _eventFetchedResultsController = nil;
  [self eventFetchedResultsController];
  [self.collectionView reloadData];
  
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
  
  __weak WASharedEventViewController *wSelf = self;
  if ([self.objectChanges count]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      if ([[[wSelf.eventFetchedResultsController sections] objectAtIndex:0] numberOfObjects] == 0) {
        // first item
        [wSelf.collectionView reloadData];
      } else {
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
      }
    });
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
  return [[[self.eventFetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  WASharedEventViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
  
  // Configure the cell...
  WAArticle *aArticle = [self.eventFetchedResultsController objectAtIndexPath:indexPath];
  cell.imageView.clipsToBounds = YES;
  
  [cell.imageView irUnbind:@"image"];
  [cell.imageView irBind:@"image"
                toObject:aArticle
                 keyPath:@"representingFile.thumbnailImage"
                 options:[NSDictionary dictionaryWithObjectsAndKeys: (id)kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
                          [^(id inOldValue, id inNewValue, NSString *changeKind) {
                            if ([inNewValue isEqual:[NSNull null]]) {
                              return [UIImage imageNamed:@"EventListPlaceHolder"];
                            } else {
                              return (UIImage*)inNewValue;
                            }
                          } copy], kIRBindingsValueTransformerBlock, nil]];
  
  NSInteger pplNumber = [[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"sharingContacts"] count];
  NSInteger photoNumbers = [[[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"files"] count];
  
  static NSDateFormatter *sharedDateFormatter;
  sharedDateFormatter = [[NSDateFormatter alloc] init];
  [sharedDateFormatter setDateStyle:NSDateFormatterLongStyle];
  [sharedDateFormatter setTimeStyle:NSDateFormatterNoStyle];
  
  NSDate *eDate = [[self.eventFetchedResultsController objectAtIndexPath:indexPath] valueForKey:@"eventStartDate"];
  NSString *eventDate = [sharedDateFormatter stringFromDate:eDate];
  
  NSString *location = @"";
  if (aArticle.location) {
    location = aArticle.location.name;
  }

  NSInteger checkinNumbers = [aArticle.checkins count];
  if (checkinNumbers) {
    NSString *checkinString = [[[aArticle.checkins allObjects] valueForKey:@"name"] componentsJoinedByString:@","];
    if (location.length && checkinString.length) {
      location = [NSString stringWithFormat:@"%@,%@", checkinString, location];
    }
  }
  
  if (!aArticle.lastRead && [aArticle.lastRead compare:aArticle.modificationDate] == NSOrderedDescending) {
    [cell.stickerNew setHidden:NO];
  } else {
    [cell.stickerNew setHidden:YES];
  }
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
  if (self.shareInstructionView) {
    [self.shareInstructionView dismissCalloutAnimated:YES];
    self.shareInstructionView = nil;
  }
  [self.view removeGestureRecognizer:self.tapGesture];
  self.tapGesture = nil;

  WANavigationController *navVC = [WADayPhotoPickerViewController viewControllerWithNavigationControllerWrapped];
  __weak WADayPhotoPickerViewController *picker = (WADayPhotoPickerViewController*)navVC.topViewController;
  picker.onNextHandler = ^(NSArray *selectedAssets) {
    
    WAPhotoTimelineViewController *photoTimeline = [[WAPhotoTimelineViewController alloc] initWithAssets:selectedAssets];
    [picker.navigationController pushViewController:photoTimeline animated:YES];
    
  };
  picker.onCancelHandler = ^{
    [picker.navigationController dismissViewControllerAnimated:YES completion:nil];
  };

  [self presentViewController:navVC animated:YES completion:nil];
}

@end
