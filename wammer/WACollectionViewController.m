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

@interface WACollectionViewController ()
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation WACollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  return self;
}

- (void)viewDidLoad{
  [super viewDidLoad];
  
  [self.collectionView registerClass:[WACollectionViewCell class] forCellWithReuseIdentifier:kCollectionViewCellID];
	
	NSPredicate *allCollections = [NSPredicate predicateWithFormat:@"isHidden == FALSE"];
	_fetchedResultsController = [WACollection MR_fetchAllSortedBy:@"title" ascending:YES withPredicate:allCollections	groupBy:nil delegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.title = NSLocalizedString(@"COLLECTIONS", @"In navigation bar");
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark Collection delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

	return [[ [_fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)aCollectionView
									        cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WACollectionViewCell *cell = [aCollectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellID forIndexPath:indexPath];
	WACollection *aCollection = [_fetchedResultsController objectAtIndexPath:indexPath];
	
	WAFile *cover = (WAFile *)[aCollection.files objectAtIndex:0];
	cell.title.text = [aCollection.title stringByAppendingFormat:@" (%d)", [aCollection.files count]];
	
	[cover irObserve:@"smallThumbnailImage"
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

@end
