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
#import "WAPartioNavigationBar.h"
#import "NSDate+WAAdditions.h"
#import "WAPhotoTimelineViewController.h"
#import <BlocksKit/BlocksKit.h>

@interface WADayPhotoPickerViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSOperationQueue *imageDisplayQueue;
@property (nonatomic, strong) NSArray *photoGroups;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSDate *selectedRangeFromDate;
@property (nonatomic, strong) NSDate *selectedRangeToDate;
@property (nonatomic, strong) NSArray *allTimeSortedAssets;

@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
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

- (id) initWithSuggestedDateRangeFrom:(NSDate*)from to:(NSDate*)to {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.selectedAssets = [NSMutableArray array];
    self.selectedRangeFromDate = from;
    self.selectedRangeToDate = to;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.imageDisplayQueue = [[NSOperationQueue alloc] init];
  self.imageDisplayQueue.maxConcurrentOperationCount = 1;
  
  __weak WADayPhotoPickerViewController *wSelf = self;
  UIBarButtonItem *buttonItem = WAPartioNaviBarButton(NSLocalizedString(@"NEXT_ACTION", @"Next"), [UIImage imageNamed:@"Btn"], nil, ^{
    if (wSelf.onNextHandler)
      wSelf.onNextHandler(wSelf.selectedAssets);
  });

  self.navigationItem.rightBarButtonItem = buttonItem;
  
  if (!self.onCancelHandler) {
    self.navigationItem.leftBarButtonItem = WAPartioBackButton(^{
      [wSelf.navigationController popViewControllerAnimated:YES];
    });
  } else {
    self.navigationItem.leftBarButtonItem = (UIBarButtonItem*)WAPartioNaviBarButton(NSLocalizedString(@"ACTION_CANCEL", @"Cancel"), [UIImage imageNamed:@"Btn1"], nil, ^{
      wSelf.onCancelHandler();
    });
  }

  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
  
  self.collectionView.allowsMultipleSelection = YES;
  [self.collectionView registerNib:[UINib nibWithNibName:@"WADayPhotoPickerViewCell" bundle:nil] forCellWithReuseIdentifier:@"WADayPhotoPickerViewCell"];
  [self.collectionView registerNib:[UINib nibWithNibName:@"WADayPhotoPickerSectionHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WADayPhotoPickerSectionHeaderView"];
  
  if (!self.selectedAssets.count) {
    self.navigationItem.rightBarButtonItem.enabled = NO;
  }
  
  [self updateNavigationBarTitle];
  
}

- (void) viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];

  __weak WADayPhotoPickerViewController *wSelf = self;
  WAOverlayBezel *busyBezel = [[WAOverlayBezel alloc] initWithStyle:WAActivityIndicatorBezelStyle];
  [busyBezel show];
  
  [[WAAssetsLibraryManager defaultManager] retrieveTimeSortedPhotosWhenComplete:^(NSArray *result) {
    wSelf.allTimeSortedAssets = result;
    [busyBezel dismiss];
    
    if (wSelf.selectedAssets.count) {
      [wSelf.collectionView reloadData];

      [wSelf.collectionView scrollToItemAtIndexPath:[wSelf indexPathForAsset:wSelf.selectedAssets[0]] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    } else if (self.selectedRangeFromDate && self.selectedRangeToDate) {
      
      for (ALAsset *asset in self.allTimeSortedAssets) {
        NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
        if ([assetDate compare:self.selectedRangeFromDate] == NSOrderedAscending)
          break;
        
        if ([assetDate compare:self.selectedRangeToDate] == NSOrderedDescending) {
          continue;
        }
        [self.selectedAssets addObject:asset];
        
      }
      
      [wSelf.collectionView reloadData];
      if (self.selectedAssets.count) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        NSIndexPath *indexPath = [wSelf indexPathForAsset:self.selectedAssets[0]];
        dispatch_async(dispatch_get_main_queue(), ^{
          [wSelf.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        });
      }
    } else {
      [wSelf.collectionView reloadData];
    }
  } onFailure:^(NSError *error) {
    [busyBezel dismiss];
    
    NSLog(@"error: %@", error);
  }];

}

- (void) updateNavigationBarTitle {
  if (self.selectedAssets) {
    self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"DAY_PHOTO_PICKER_PHOTOS_SELECTED", @"Show how many photos selected in the day photo picker"), self.selectedAssets.count];
  } else {
    self.navigationItem.title = NSLocalizedString(@"TITLE_OF_DAY_PHOTO_PICKER", @"Title of the day photo picker view");
  }
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
  
  if (self.selectedAssets.count)
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
  
  [self updateNavigationBarTitle];
  
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

  ALAsset *asset = (ALAsset*)self.photoGroups[indexPath.section][indexPath.row];
  if (self.selectedAssets != nil && [self.selectedAssets indexOfObject:asset] != NSNotFound) {
    [self.selectedAssets removeObject:asset];
  }
  
  if (!self.selectedAssets.count)
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
  
  [self updateNavigationBarTitle];
}

@end
