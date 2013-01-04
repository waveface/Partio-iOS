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
#import "WAFile.h"
#import <CoreData+MagicalRecord.h>
#import "WAGalleryViewController.h"
#import <MKNetworkKit/MKNetworkKit.h>
#import "WARemoteInterface+Authentication.h"
#import <WADataStore+WARemoteInterfaceAdditions.h>

typedef NS_ENUM(NSUInteger, WACollectionSortMode){
  WACollectionSortByName = 0,
  WACollectionSortByDate,
};

@interface WACollectionViewController () {
  WACollectionSortMode mode;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
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

- (void)reloadCollection {
  NSPredicate *allCollections = [NSPredicate predicateWithFormat:@"isHidden == FALSE"];
  _fetchedResultsController = [WACollection MR_fetchAllSortedBy:(mode == WACollectionSortByName)? @"title": @"modificationDate"
					    ascending:(mode == WACollectionSortByName)? YES: NO
					withPredicate:allCollections
					      groupBy:nil
					     delegate:self];
  
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

- (void)viewDidLoad{
  [super viewDidLoad];
  
  [self.collectionView registerClass:[WACollectionViewCell class] forCellWithReuseIdentifier:kCollectionViewCellID];
  
  _refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0, -44, 320, 44)];
  [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
  [self.collectionView addSubview:_refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if ([WACollection MR_countOfEntities]==0) {
    [self refresh];
  }
  self.title = NSLocalizedString(@"COLLECTIONS", @"In navigation bar");
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Collection delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  
  return [[ [_fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)aCollectionView
	        cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  WACollectionViewCell *cell = [aCollectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellID
							    forIndexPath:indexPath];
  WACollection *aCollection = [_fetchedResultsController objectAtIndexPath:indexPath];
  
  cell.title.text = [aCollection.title stringByAppendingFormat:@" (%d)", [aCollection.files count]];
  
  //Document
  WAFile *coverFile = aCollection.cover;
  if ([coverFile.pageElements count]) {
    coverFile = coverFile.pageElements[0];
  }
  
  [coverFile irObserve:@"thumbnailImage"
	     options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
	     context:nil
	   withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	     dispatch_async(dispatch_get_main_queue(), ^{
	       ((WACollectionViewCell *)[aCollectionView cellForItemAtIndexPath:indexPath]).coverImage.image = (UIImage*)toValue;
	     });
	   }];
  
  
  return (UICollectionViewCell *)cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
  WACollection *aCollection = [_fetchedResultsController objectAtIndexPath:indexPath];
  WAGalleryViewController *galleryVC = [[WAGalleryViewController alloc]
                                        initWithImageFiles:[aCollection.files array]
                                        atIndex:[indexPath row]];
  [self.navigationController pushViewController:galleryVC animated:YES];
}

#pragma mark - Private Methods

- (void)refresh {
  WARemoteInterface *interface = [WARemoteInterface sharedInterface];
  MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:@"develop.waveface.com"];
  MKNetworkOperation *op = [engine operationWithPath:@"v3/collections/getAll"
                                              params:@{
		        @"session_token":interface.userToken,
		        @"api_key":interface.apiKey}
                                          httpMethod:@"GET"];
  op.freezable = YES;
  [op addCompletionHandler:^(MKNetworkOperation *completedOperation)
   {
   [_refreshControl endRefreshing];
   NSError *error;
   NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[completedOperation responseData]
						options:NSJSONReadingAllowFragments
						  error:&error];
   
   NSManagedObjectContext *moc = [NSManagedObjectContext MR_context];
   moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
   
   NSArray *collections = [WACollection
		       insertOrUpdateObjectsUsingContext:moc
		       withRemoteResponse:[response objectForKey:@"collections"]
		       usingMapping:nil
		       options:IRManagedObjectOptionIndividualOperations
		       ];
   [moc save:nil];
   [self reloadCollection];
   [self.collectionView reloadData];
   }
	    errorHandler:^(MKNetworkOperation *completedOperation, NSError *error)
   {
   NSLog(@"Failed %@", completedOperation);
   [_refreshControl endRefreshing];
   }];
  
  //  MKNetworkOperation *op = [engine operationWithPath:@"https://develop.waveface.com/v2/attachments/multiple_get?session_token=b31tbLA0SYCwHXDZR9qf7A2n.fIn9nQMUri8c5J%2Fgi3stz0w5CgE7i5E6PNGSDz9QLM8&apikey=ca5c3c5c-287d-5805-93c1-a6c2cbf9977c"];
  [engine enqueueOperation:op];
}
@end
