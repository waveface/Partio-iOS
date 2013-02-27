//
//  WACollectionOverviewViewController.m
//  wammer
//
//  Created by jamie on 13/2/21.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WACollectionOverviewViewController.h"
#import "WAFile+LazyImages.h"
#import "WAGalleryViewController.h"
#import "WACollection.h"
#import "WACollectionOverviewViewCell.h"
@interface WACollectionOverviewViewController ()

@end

@implementation WACollectionOverviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  [self.collectionView registerClass:[WACollectionOverviewViewCell class]
          forCellWithReuseIdentifier:@"WACollectionOverviewViewCell"];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  for (WAFile *target in _collection.files) {
    [target irRemoveAllObserves];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return [_collection.files count];
}

- (WACollectionOverviewViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  WACollectionOverviewViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WACollectionOverviewViewCell" forIndexPath:indexPath];
  
  WAFile *target = (WAFile*)[_collection.files objectAtIndex:[indexPath row]];

  if (target.smallThumbnailImage) {
    cell.imageView.image = target.smallThumbnailImage;
  } else {
    [target irObserve:@"smallThumbnailImage"
              options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
              context:nil
            withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
                cell.imageView.image = toValue;
            }];
  }
  
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Collection" withAction:@"Enter Gallery" withLabel:nil withValue:@0];
  
  WAGalleryViewController *galleryVC = [[WAGalleryViewController alloc]
                                        initWithImageFiles:[_collection.files array]
                                        atIndex:[indexPath row]];
  [self.navigationController pushViewController:galleryVC animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
  WAFile *target = (WAFile*)[_collection.files objectAtIndex:[indexPath row]];
  [target irRemoveAllObserves];
}
@end
