//
//  WADayPhotoPickerViewController.m
//  wammer
//
//  Created by Shen Steven on 4/8/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WADayPhotoPickerViewController.h"
#import "WAAssetsLibraryManager.h"
#import "ALAsset+WAAdditions.h"
#import "WADayPhotoPickerViewCell.h"
#import "WADayPhotoPickerSectionHeaderView.h"
#import "WAEventPhotoPickerLoadingView.h"
#import "WAOverlayBezel.h"
#import "WAPartioNavigationBar.h"
#import "NSDate+WAAdditions.h"
#import "WADataStore+FetchingConveniences.h"
#import "WAPhotoTimelineViewController.h"
#import "WANavigationController.h"
#import "WAEventPhotoPickerDataSource.h"
#import <BlocksKit/BlocksKit.h>

@interface WADayPhotoPickerViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSOperationQueue *imageDisplayQueue;
@property (nonatomic, strong) NSArray *photoGroups;
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSDate *selectedRangeFromDate;
@property (nonatomic, strong) NSDate *selectedRangeToDate;
@property (nonatomic, strong) NSArray *allTimeSortedAssets;
@property (nonatomic, strong) NSMutableSet *selectedSections;
@property (nonatomic, strong) WAEventPhotoPickerDataSource *dataSource;

@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
@end

@implementation WADayPhotoPickerViewController

+ (id) viewControllerWithNavigationControllerWrapped {
  
  WADayPhotoPickerViewController *vc = [[WADayPhotoPickerViewController alloc] initWithSelectedAssets:nil];
  WANavigationController *navigationController = [[WANavigationController alloc] initWithRootViewController:vc];
  navigationController.navigationBarHidden = YES;
  navigationController.toolbarHidden = YES;
  return navigationController;
  
}

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
  self.selectedSections = [NSMutableSet set];
  
  __weak WADayPhotoPickerViewController *wSelf = self;
  
  if (!self.actionButtonLabelText)
    self.actionButtonLabelText = NSLocalizedString(@"PREVIEW_ACTION", @"Preview");

  UIBarButtonItem *buttonItem = WAPartioNaviBarButton(self.actionButtonLabelText, [UIImage imageNamed:@"Btn"], nil, ^{
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
  
  [self.collectionView registerNib:[UINib nibWithNibName:@"WAEventPhotoPickerLoadingView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WAEventPhotoPickerLoadingView"];
  
  if (!self.selectedAssets.count) {
    self.navigationItem.rightBarButtonItem.enabled = NO;
  }
  
  [self updateNavigationBarTitle];
  
}

- (void) updateNavigationBarTitle {
  if (self.selectedAssets.count) {
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

- (void) selectAssetsFrom:(NSDate*)fromDate to:(NSDate*)toDate {
  NSUInteger section = 0;
  NSIndexPath *firstIndexPath = nil;
  
  NSAssert(fromDate && toDate, @"require the date range");
  
  NSMutableArray *changedIndexPaths = [NSMutableArray array];
  for (section = 0; section < self.dataSource.numberOfEvents; section++) {
    NSArray *assets = [self.dataSource photosInEvent:section] ;
    NSUInteger row = 0;
    BOOL stop = NO;
    for (row = 0; row < assets.count; row ++) {
      ALAsset *asset = assets[row];
      NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
      if ([toDate compare:date] == NSOrderedAscending)
        continue;
      if ([fromDate compare:date] == NSOrderedDescending) {
        stop = YES;
        break;
      }
      
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
      if (!firstIndexPath)
        firstIndexPath = indexPath;
      [self.collectionView selectItemAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UICollectionViewScrollPositionNone];
      [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
      [changedIndexPaths addObject:indexPath];
    }
    if (stop)
      break;
  }
  
  if (firstIndexPath) {
    [self.collectionView reloadItemsAtIndexPaths:changedIndexPaths];
    [self.collectionView scrollToItemAtIndexPath:firstIndexPath
                                atScrollPosition:UICollectionViewScrollPositionTop
                                        animated:YES];
  }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

  return [self.dataSource numberOfEvents] + 1;
  
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  
  if (section == [self.dataSource numberOfEvents])
    return 0;
  
  return [self.dataSource numberOfPhotosInEvent:section];

}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  __weak WADayPhotoPickerViewController *wSelf = self;
  WADayPhotoPickerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WADayPhotoPickerViewCell" forIndexPath:indexPath];

  if (cell.imageLoadingOperation) {
    [cell.imageLoadingOperation cancel];
  }
  
  cell.imageLoadingOperation = [NSBlockOperation blockOperationWithBlock:^{
  
    ALAsset *asset = [self.dataSource photoAtIndexPath:indexPath];
    UIImage *image = [UIImage imageWithCGImage:[(ALAsset*)asset thumbnail]];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      cell.imageView.image = image;
      ALAsset *asset = [self.dataSource photoAtIndexPath:indexPath];
      if (wSelf.selectedAssets != nil && [wSelf.selectedAssets containsObject:asset]) {
        [wSelf.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
      }

    }];
  }];
  [self.imageDisplayQueue addOperation:cell.imageLoadingOperation];
    
  return cell;
}

- (CLLocation *)gpsMetaWithinPhotos:(NSArray*)assets {

  for (ALAsset *asset in assets) {
    CLLocation *location = asset.gpsLocation;
    if (location)
      return location;
  }
  return nil;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  
  if (![kind isEqualToString:UICollectionElementKindSectionHeader])
    return nil;
  if (indexPath.section != [self.dataSource numberOfEvents]) {
    WADayPhotoPickerSectionHeaderView * header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WADayPhotoPickerSectionHeaderView" forIndexPath:indexPath];
    
    ALAsset *asset = [self.dataSource photoAtIndexPath:indexPath];
    NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
  
    if ([self.selectedSections containsObject:@(indexPath.section)]) {
      [header.addButton setTitle:NSLocalizedString(@"BUTTON_DESELECT_ALL", @"") forState:UIControlStateNormal];
    } else {
      [header.addButton setTitle:NSLocalizedString(@"BUTTON_SELECT_ALL", @"") forState:UIControlStateNormal];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
    header.titleLabel.text = [formatter stringFromDate:date];

    header.locationLabel.text = @"";
    
    NSArray *assets = [self.dataSource photosInEvent:indexPath.section];
    NSDate *beginDate = [[assets lastObject] valueForProperty:ALAssetPropertyDate];
    NSDate *endDate = [assets[0] valueForProperty:ALAssetPropertyDate];
                       
    NSFetchRequest * fetchRequest = [[WADataStore defaultStore] newFetchReuqestForCheckinFrom:beginDate to:endDate];
    
    NSError *error = nil;
    NSArray *checkins = [[[WADataStore defaultStore] disposableMOC] executeFetchRequest:fetchRequest error:&error];
    if (error) {
      NSLog(@"error to query checkin db: %@", error);
    } else if (checkins.count) {
      header.locationLabel.text = [[checkins valueForKeyPath:@"name"] componentsJoinedByString:@","];
    }

    CLLocation *gps = [self gpsMetaWithinPhotos:assets];
    if (gps) {
      if (header.geoLocation)
        [header.geoLocation cancel];
      
      header.geoLocation = [[WAGeoLocation alloc] init];
      [header.geoLocation identifyLocation:gps.coordinate
                              onComplete:^(NSArray *results) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                  
                                  if (header.locationLabel.text.length)
                                    header.locationLabel.text = [NSString stringWithFormat:@"%@,%@", header.locationLabel.text, [results componentsJoinedByString:@","]];
                                  else
                                    header.locationLabel.text = [results componentsJoinedByString:@","];
                                  
                                });
                                
                              } onError:^(NSError *error) {
                                
                                NSLog(@"geolocation error: %@", error);
                                
                              }];

    }
    header.addButton.tag = indexPath.section;
    return header;
  } else {
    WAEventPhotoPickerLoadingView *loading = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WAEventPhotoPickerLoadingView" forIndexPath:indexPath];
    __weak WADayPhotoPickerViewController *wSelf = self;
    
    if (!self.dataSource) {
      // initial loading
      if (self.selectedRangeFromDate) {
        NSDate *newFromDate = [self.selectedRangeFromDate dateByAddingTimeInterval:(-24 * 2 * 60 * 60)];

        dispatch_async(dispatch_get_main_queue(), ^{
          
          wSelf.dataSource = [[WAEventPhotoPickerDataSource alloc] initWithPhotosLoadedUntil:newFromDate completionHandler:^(NSIndexSet *changedSections) {
            [wSelf.collectionView reloadData];
            [wSelf performBlock:^(id sender) {
              
              [wSelf selectAssetsFrom:wSelf.selectedRangeFromDate to:wSelf.selectedRangeToDate];
              
            } afterDelay:0.8];
            
          }];
          
        });

      } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          
          wSelf.dataSource = [[WAEventPhotoPickerDataSource alloc] initWithCompletionHandler:^(NSIndexSet *changedSections) {
            [wSelf.collectionView reloadData];
          }];
        });

      }
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [wSelf.dataSource loadMoreEvents];
      });

    }
    
    return loading;
  }
  
  return nil;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

  ALAsset *asset = [self.dataSource photoAtIndexPath:indexPath];
  if (self.selectedAssets != nil && [self.selectedAssets indexOfObject:asset] == NSNotFound) {
    [self.selectedAssets addObject:asset];
  }
  
  if (self.selectedAssets.count)
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
  
  [self updateNavigationBarTitle];
  
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

  ALAsset *asset = [self.dataSource photoAtIndexPath:indexPath];
  if (self.selectedAssets != nil && [self.selectedAssets indexOfObject:asset] != NSNotFound) {
    [self.selectedAssets removeObject:asset];
  }
  
  if (!self.selectedAssets.count)
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
  
  [self updateNavigationBarTitle];
}

- (void) selectAllInSection:(NSUInteger)section {
  NSUInteger numberOfItem = [self.collectionView numberOfItemsInSection:section];

  for (int i = 0; i < numberOfItem; i++) {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];

    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
  }
  [self.selectedSections addObject:@(section)];
}

- (void) deselectAllInSection:(NSUInteger)section {
  NSUInteger numberOfItem = [self.collectionView numberOfItemsInSection:section];
  
  for (int i = 0; i < numberOfItem; i++) {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    [self collectionView:self.collectionView didDeselectItemAtIndexPath:indexPath];
  }
  [self.selectedSections removeObject:@(section)];
}

@end
