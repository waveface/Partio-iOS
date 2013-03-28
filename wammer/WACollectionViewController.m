//
//  WACollectionViewController.m
//  wammer
//
//  Created by jamie on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACollectionViewController.h"
#import "WACollectionViewCell.h"
#import "WACollection.h"
#import "WACollection+RemoteOperations.h"
#import "WAFile.h"
#import <CoreData+MagicalRecord.h>
#import <MKNetworkKit/MKNetworkKit.h>
#import "WARemoteInterface+Authentication.h"
#import <WADataStore+WARemoteInterfaceAdditions.h>
#import "WACollectionOverviewViewController.h"
#import "WADataStore.h"
#import "WALocalizedLabel.h"

typedef NS_ENUM(NSUInteger, WACollectionSortMode){
  WACollectionSortByName = 0,
  WACollectionSortByDate,
};

@interface WACollectionViewController () {
  WACollectionSortMode mode;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSManagedObjectContext *moc;

@end

@implementation WACollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    mode = WACollectionSortByName;
  }
  return self;
}

#pragma mark - UIViewController delegate

- (void)viewDidLoad{
  [super viewDidLoad];
  
  [self.collectionView registerClass:[WACollectionViewCell class] forCellWithReuseIdentifier:kCollectionViewCellID];
  
  _refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0, -44, 320, 44)];
  [_refreshControl addTarget:self action:@selector(refreshAllCollectionMetas) forControlEvents:UIControlEventValueChanged];
  [self.collectionView addSubview:_refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.title = NSLocalizedString(@"COLLECTIONS", @"In navigation bar");
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updated:) name:kWACollectionUpdated object:nil];
  
  //  if ([WACollection MR_countOfEntities] == 0) {
  [self reloadCollection];
  [self.collectionView reloadData];
  //  }
  _coachLabel.hidden = !![self.collectionView numberOfItemsInSection:0];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
  return NO;
}

#pragma mark - Collection delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  
  return [[ [_fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (WACollectionViewCell *)collectionView:(UICollectionView *)aCollectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  WACollectionViewCell *cell = [aCollectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellID
                                                                          forIndexPath:indexPath];
  
  WACollection *aCollection = [_fetchedResultsController objectAtIndexPath:indexPath];
  
  if (!cell)
    return nil;
  
  cell.title.text = [aCollection.title stringByAppendingFormat:@" (%d)", [aCollection.files count]];
  
  WAFile *coverFile = (aCollection.cover)?aCollection.cover:aCollection.files[0];
  
  //Document
  if ([coverFile.pageElements count]) {
    coverFile = coverFile.pageElements[0];
  }
  
  cell.cover = coverFile;
  
  [cell.cover irObserve:@"smallThumbnailImage"
               options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew)
                 context:nil
               withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
                 cell.coverImage.image = toValue;
               }];
  
  return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
  [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Collection" withAction:@"Enter Overview" withLabel:nil withValue:@0];
  
  WACollectionOverviewViewController *overviewViewController = [[WACollectionOverviewViewController alloc] init];
  
  overviewViewController.collectionURI =[[[_fetchedResultsController objectAtIndexPath:indexPath] objectID] URIRepresentation];
  
  [self.navigationController pushViewController:overviewViewController animated:YES];
}

#pragma mark - Private Methods

/* Update all collections. Very slow, use with caution. */
- (void)refreshAllCollectionMetas {
  WACollectionViewController __weak *weakSelf = self;
  
  //  [WACollection refreshCollectionsWithCompletion:^{
  [weakSelf.refreshControl endRefreshing];
  [weakSelf reloadCollection];
  //    [weakSelf.collectionView reloadData];
  //  }];
}

- (void)updated:(NSNotification *)notification {
  [self.refreshControl endRefreshing];
}

- (void)reloadCollection {
  NSPredicate *allCollections = [NSPredicate predicateWithFormat:@"isHidden == FALSE AND files.@count > 0"];
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WACollection"];
  //TODO: sort by time or sort by title
  
  _moc = [[WADataStore defaultStore] defaultAutoUpdatedMOC];

  fetchRequest.predicate = allCollections;
  if (mode == WACollectionSortByName) {
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
  } else {
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO]];
  }
  
  _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_moc sectionNameKeyPath:nil cacheName:@"WACollection All"];
  _fetchedResultsController.delegate = self;
  
  NSError *error;
  if (![_fetchedResultsController performFetch:&error]) {
    NSLog(@"Error: %@", error);
  }
  
//  _fetchedResultsController = [WACollection MR_fetchAllSortedBy:(mode == WACollectionSortByName)? @"title": @"modificationDate"
//                                                      ascending:(mode == WACollectionSortByName)? YES: NO
//                                                  withPredicate:allCollections
//                                                        groupBy:nil
//                                                       delegate:self
//                                                      inContext:[[WADataStore defaultStore] autoUpdatingMOC]];
  
  NSString *title = (mode == WACollectionSortByName)?
  NSLocalizedString(@"By Name", @"Collection View Navigation Bar"):
  NSLocalizedString(@"By Date", @"Collection View Navigation Bar");
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(toggleMode)];
}

- (void)toggleMode {
  if (mode == WACollectionSortByName) {
    mode = WACollectionSortByDate;
  } else
    mode = WACollectionSortByName;
  
  [self reloadCollection];
  [self.collectionView reloadData];
}

#pragma mark - UIEvent Callbacks

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
  
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
  // Shake to refresh collections (solicit)
  if (motion == UIEventSubtypeMotionShake) {
    [self refreshAllCollectionMetas];
  }
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

@end
