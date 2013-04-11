//
//  WADayPhotoPickerViewController.m
//  wammer
//
//  Created by Shen Steven on 4/8/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WADayPhotoPickerViewController.h"
#import "WAAssetsLibraryManager.h"
#import "WADayPhotoPickerViewCell.h"
#import "WADayPhotoPickerSectionHeaderView.h"
#import "WAOverlayBezel.h"
#import "NSDate+WAAdditions.h"
#import "WAPhotoTimelineViewController.h"
#import <BlocksKit/BlocksKit.h>

@interface WADayPhotoPickerViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSOperationQueue *imageDisplayQueue;
@property (nonatomic, strong) NSArray *photoGroups;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSArray *allTimeSortedAssets;

@end

@implementation WADayPhotoPickerViewController


- (id) initWithSelectedAssets:(NSArray *)assets {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    if (assets)
      self.selectedAssets = [NSMutableArray arrayWithArray:assets];
    else
      self.selectedAssets = [NSMutableArray array];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = NSLocalizedString(@"TITLE_OF_DAY_PHOTO_PICKER", @"Title of the day photo picker view");
  self.imageDisplayQueue = [[NSOperationQueue alloc] init];
  self.imageDisplayQueue.maxConcurrentOperationCount = 1;
  
  if (self.navigationController) {
    __weak WADayPhotoPickerViewController *wSelf = self;
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create" style:UIBarButtonItemStyleBordered handler:^(id sender) {
      WAPhotoTimelineViewController *photoTimeline = [[WAPhotoTimelineViewController alloc] initWithAssets:wSelf.selectedAssets];
      
      [wSelf.navigationController pushViewController:photoTimeline animated:YES];
    }];

    self.navigationItem.rightBarButtonItem = buttonItem;
  }
  
  self.collectionView.allowsMultipleSelection = YES;
  [self.collectionView registerNib:[UINib nibWithNibName:@"WADayPhotoPickerViewCell" bundle:nil] forCellWithReuseIdentifier:@"WADayPhotoPickerViewCell"];
  [self.collectionView registerNib:[UINib nibWithNibName:@"WADayPhotoPickerSectionHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WADayPhotoPickerSectionHeaderView"];
}
- (void) viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];

  __weak WADayPhotoPickerViewController *wSelf = self;
  WAOverlayBezel *busyBezel = [[WAOverlayBezel alloc] initWithStyle:WAActivityIndicatorBezelStyle];
  [busyBezel show];
  
  [[WAAssetsLibraryManager defaultManager] retrieveTimeSortedPhotosWhenComplete:^(NSArray *result) {
    wSelf.allTimeSortedAssets = result;
    [busyBezel dismiss];
    
    [wSelf.collectionView reloadData];
    
    if (wSelf.selectedAssets.count) {
      [wSelf.collectionView scrollToItemAtIndexPath:[wSelf indexPathForAsset:wSelf.selectedAssets[0]] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    }
  } onFailure:^(NSError *error) {
    [busyBezel dismiss];
    
    NSLog(@"error: %@", error);
  }];

}

- (void) viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self.imageDisplayQueue cancelAllOperations];
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (NSArray*) photoGroups {
  
  if (_photoGroups.count > 0)
    return _photoGroups;
  
  if (_allTimeSortedAssets.count == 0)
    return @[];
  
  NSMutableArray *sortedGroups = [NSMutableArray array];
  NSMutableArray *photoList = [NSMutableArray array];
  __block NSDate *previousDate = nil;
  
  [_allTimeSortedAssets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
    
    if (!previousDate) {
      [photoList addObject:asset];
      previousDate = [asset valueForProperty:ALAssetPropertyDate];
      
    } else {
      
      NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
      
      if(!isSameDay(assetDate, previousDate)) {
        
        previousDate = assetDate;
        [sortedGroups addObject:[photoList copy]];
        [photoList removeAllObjects];
        [photoList addObject:asset];
        
      } else {
        
        previousDate = assetDate;
        [photoList addObject:asset];
        
      }
    }
    
  }];
  
  _photoGroups = [NSArray arrayWithArray:sortedGroups];
  return _photoGroups;
}

- (NSIndexPath *)indexPathForAsset:(ALAsset*)targetAsset {
 
  NSDate *targetDate = [targetAsset valueForProperty:ALAssetPropertyDate];
  NSInteger section = 0;
  for (NSArray *group in self.photoGroups) {
    NSDate *date = [(ALAsset *)group[0] valueForProperty:ALAssetPropertyDate];
    if (isSameDay(targetDate, date)) {
      NSInteger row = 0;
      for (ALAsset *item in self.photoGroups[section]) {
        if ([item isEqual:targetAsset]) {
          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
          return indexPath;
        }
        row ++;
      }
      
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
      return indexPath;
    }
    
    if ([targetDate compare:date] == NSOrderedDescending) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
      return indexPath;
    }
    
    section ++;
  }
  return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (void) scrollToDate:(NSDate*)targetDate {

  NSInteger index = 0;
  
  for (NSArray *group in self.photoGroups) {
    NSDate *date = [(ALAsset*)group[0] valueForProperty:ALAssetPropertyDate];
    if (isSameDay(targetDate, date))
      break;
    
    if ([targetDate compare:date] == NSOrderedDescending)
      break;
      
    index ++;
  }
  
  [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return self.photoGroups.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  
  return [self.photoGroups[section] count];
  
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  __weak WADayPhotoPickerViewController *wSelf = self;
  WADayPhotoPickerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WADayPhotoPickerViewCell" forIndexPath:indexPath];
  
  NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
    
    UIImage *image = [UIImage imageWithCGImage:[(ALAsset*)wSelf.photoGroups[indexPath.section][indexPath.row] thumbnail]];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      cell.imageView.image = image;
      ALAsset *asset = self.photoGroups[indexPath.section][indexPath.row];
      if (wSelf.selectedAssets != nil && [wSelf.selectedAssets indexOfObject:asset] != NSNotFound) {
        [wSelf.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
      }

    }];
  }];
  [self.imageDisplayQueue addOperation:op];
  
  
  return cell;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  
  if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
    WADayPhotoPickerSectionHeaderView * header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WADayPhotoPickerSectionHeaderView" forIndexPath:indexPath];
    
    ALAsset *asset = self.photoGroups[indexPath.section][0];
    NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
  
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    header.titleLabel.text = [formatter stringFromDate:date];

    return header;
  }
  
  return nil;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

  ALAsset *asset = (ALAsset*)self.photoGroups[indexPath.section][indexPath.row];
  if (self.selectedAssets != nil && [self.selectedAssets indexOfObject:asset] == NSNotFound) {
    [self.selectedAssets addObject:asset];
  }
  
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

  ALAsset *asset = (ALAsset*)self.photoGroups[indexPath.section][indexPath.row];
  if (self.selectedAssets != nil && [self.selectedAssets indexOfObject:asset] != NSNotFound) {
    [self.selectedAssets removeObject:asset];
  }

}

@end
